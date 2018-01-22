defmodule Server do
    use GenServer
    def start_link(no_users) do
        val = 0
        sum = generate_zipf_constant(0, no_users)
        # IO.inspect sum
        c = 1/sum
        #name = ""
        GenServer.start_link(__MODULE__, %{zj: 0, number: no_users, registered_users: val, zipf_c: c, tweetid: 0}, name: {:global, TwitterServer})
        {:ok, ifs} = :inet.getif()
        ips = for {ip, _, _} <- ifs, do: to_string(:inet.ntoa(ip))
        this_ip = Enum.at(ips,Enum.count(ips)-1)#to_string(hd(ips))
        server_name = "server@" <> this_ip
        # IO.puts server_name
        Node.start(:"#{server_name}")
        Node.set_cookie :sugar
        :global.sync()
        #:global.register_name(:Server, server_pid)
        # IO.inspect server_pid
        # IO.inspect :global.registered_names()
        :timer.sleep(:infinity)
    end

    def init(state) do
        #table is of the below format
        :ets.new(:users, [:set, :named_table, :public])#, write_concurrency: true, read_concurrency: true]) #username   password    online  [followers]   [following]   [offline_msgs] = [{tweetid, msg}]
        # :ets.new(:tweets, [:bag, :named_table, :public]) #tweetid, userid, message
        :ets.new(:hashtag, [:set, :named_table, :public])#, write_concurrency: true, read_concurrency: true]) #hashtag, [tweetid]
        :ets.new(:mentions, [:set, :named_table, :public])#, write_concurrency: true, read_concurrency: true]) #username, [tweetid]
        {:ok, state}
    end
    
    def register_user(server, username, password) do
        GenServer.cast({:global, TwitterServer}, {:registerUser, username, password})
    end

    def handle_cast({:registerUser, username, password}, state) do
        {:number, no_users} = Enum.at(state, 0)
        {:registered_users, reg_users} = Enum.at(state, 1)
        {:zipf_c, c} = Enum.at(state, 3)
        new_state = state
        cond do
            reg_users < no_users ->
                reg_users = reg_users + 1
                new_state = Map.put(state, :registered_users, reg_users)
                :ets.insert(:users, {username, password, true, [], [], []})
                if (reg_users == no_users) do
                    IO.puts "Registration completed."
                    generate_followers(no_users, c)
                end
        end
        {:noreply, new_state}
    end

    def generate_followers(no_users, c) do
        user_range = 1..no_users
        Enum.each(user_range, fn(x) ->
            num = (c / x) * no_users
            num = Float.round(num, 0)
            if (num > 0) do
                foll_list = generate_for_one_user(x, num, Enum.to_list(user_range), [])
                [row] = :ets.lookup(:users, x)
                :ets.insert(:users, {x, x, true, foll_list, elem(row , 3), []})
                Client.update_follower_count(num, x)
                Enum.each(foll_list, fn(follower) ->
                    #IO.puts "follower = #{follower}"
                    update_following_list(follower, x)
                end)
            end
        end)
        # Enum.each(user_range, fn(x) ->
        #     IO.inspect :ets.lookup(:users, x)
        # end)
    end

    def generate_for_one_user(user, num, no_users, foll_list) do
        follower = Enum.random(no_users)
        #IO.inspect follower
        if (num > 0) do
            if (!Enum.member?(foll_list, follower)) do
                if (follower != user) do
                    foll_list = Enum.concat([follower], foll_list)
                    generate_for_one_user(user, num - 1, no_users, foll_list)
                else
                    generate_for_one_user(user, num, no_users, foll_list)
                end
            else
                generate_for_one_user(user, num, no_users, foll_list)
            end
        else
            foll_list
        end
    end

    def add_followerlist(username, foll_list) do
        :ets.insert(:users, {username, username, true, foll_list, [], []})
    end

    def generate_zipf_constant(sum, no_users) do
        if (no_users > 0) do
            sum = sum + (1 / no_users)
            generate_zipf_constant(sum, no_users - 1)
        else
            sum
        end
    end
    def update_following_list(follower, username) do
        [result] = :ets.lookup(:users, follower)
        followers_list = elem(result, 3)
        following_list = elem(result, 4)
        following_list = following_list ++ [username]
        :ets.insert(:users, {follower, follower, true, followers_list, following_list, []})
    end

    #type
    #0 - Tweet
    #1 - Retweet
    def send_tweet(message, this_user, type) do
        GenServer.cast({:global, TwitterServer}, {:send_tweet, message, this_user, type})
    end

    def handle_cast({:send_tweet, message, this_user, type}, state) do
        hashtags = Regex.scan(~r/#[a-zA-Z0-9_]+/, message)|> Enum.concat
        mentions = Regex.scan(~r/@[a-zA-Z0-9_]+/, message)|> Enum.concat
        # IO.inspect state
        {:tweetid, tweet_count} = Enum.at(state, 2)
        tweet_count = tweet_count + 1
        tweetid = "%#{this_user}%" <> message
        if (type == 0) do #normal tweets; 1 - retweets
            if (hashtags != []) do
                Enum.each(hashtags, fn(x) -> #inserts into the table if no entry found for the hashtag else appends and inserts
                    table_val = :ets.lookup(:hashtag, x)
                    if (table_val != []) do
                        [table_val] = table_val
                        tweet_ids = elem(table_val, 1)
                        tweet_ids = tweet_ids ++ ["%#{this_user}%" <> message]#[tweetid]
                        :ets.insert(:hashtag, {x, tweet_ids})
                    else
                        :ets.insert(:hashtag, {x, [tweetid]})
                    end
                end)
            end
            if (mentions != []) do
                Enum.each(mentions, fn(x) -> #inserts into the table if no entry found for the mention else appends and inserts
                    table_val = :ets.lookup(:mentions, x)
                    if (table_val != []) do
                        [table_val] = table_val
                        tweet_ids = elem(table_val, 1)
                        tweet_ids = tweet_ids ++ ["%#{this_user}%" <> message]#[tweetid]
                        :ets.insert(:mentions, {x, tweet_ids})
                    else
                        :ets.insert(:mentions, {x, ["%#{this_user}%" <> message]})#tweetid]})
                    end
                end)
            end
        end
        [user_data] = :ets.lookup(:users, this_user)
        followers = elem(user_data, 3)
        Enum.each(followers, fn(x) ->
            [x_user_data] = :ets.lookup(:users, x)
            user_ol = elem(x_user_data, 2)
            # IO.inspect user_ol
            # IO.inspect :ets.lookup(:users, x)
            if user_ol do
                # IO.puts "here for #{x}"
                Client.receive_tweet("#{x}", tweetid, message, this_user) #add username here
            else
                offline_msgs = elem(x_user_data, 5)
                offline_msgs = offline_msgs ++ [tweetid]
                password = elem(x_user_data, 1)
                this_followers = elem(x_user_data, 3)
                this_following = elem(x_user_data, 4)
                # IO.inspect offline_msgs
                #put into user table again
                :ets.insert(:users, {x, password, false, this_followers, this_following, offline_msgs})
            end
        end)
        state = Map.put(state, :tweetid, tweet_count)
        {:noreply, state}
    end

    def query_hashtag(hashtag, username) do
        GenServer.cast({:global, TwitterServer}, {:query_hashtags, hashtag, username})
    end

    def handle_cast({:query_hashtags, hashtag, username}, state) do
        tweets = :ets.lookup(:hashtag, hashtag)
        if tweets == [] do
            tweets =[]
        else
            [{_, tweets}] = tweets
        end
        Client.print_query(tweets, hashtag, username)
        {:noreply, state}
    end

    def query_mentions(mention, username) do
        GenServer.cast({:global, TwitterServer}, {:query_mentions, mention, username})
    end

    def handle_cast({:query_mentions, mention, username}, state) do
        mentions = :ets.lookup(:mentions, mention)
        if mentions == [] do
            mentions = []
        else
            [{_, mentions}] = mentions
        end
        Client.print_query(mentions, mention, username)
        {:noreply, state}
    end

    def update_online(username) do
        GenServer.cast({:global, TwitterServer}, {:update_online, username})
    end

    def handle_cast({:update_online, username}, state) do
        [user_data] = :ets.lookup(:users, username)
        # IO.inspect user_data
        offline_tweets = elem(user_data, 5)
        :ets.insert(:users, {elem(user_data, 0), elem(user_data, 1), true, elem(user_data, 3), elem(user_data, 4), []})
        Client.get_offline_tweets(offline_tweets, username)
        {:noreply, state}
    end

    def update_offline(username) do
        GenServer.cast({:global, TwitterServer}, {:update_offline, username})
    end

    def handle_cast({:update_offline, username}, state) do
        [user_data] = :ets.lookup(:users, username)
        # IO.inspect user_data#elem(user_data, 0)
        :ets.insert(:users, {elem(user_data, 0), elem(user_data, 1), false, elem(user_data, 3), elem(user_data, 4), elem(user_data, 5)})
        # IO.inspect :ets.lookup(:users, elem(user_data,0))
        {:noreply, state}
    end
end