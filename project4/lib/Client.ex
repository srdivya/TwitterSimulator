defmodule Client do
    use GenServer
    def start_link(user_name, password, total_users) do
        user_process = :"#{user_name}"
        GenServer.start_link(__MODULE__, %{z: 0, name: user_name, password: password, tweetids: [], tweets: [], hashtags: [], users: total_users, xuser_follower_count: 0, your_count: 0, your_total_count: 0}, name: {:global, user_process})
        #IO.puts "username = #{user_name}"
        #:global.register_name(:"#{user_name}", this_pid)
        :global.sync()
        Server.register_user(TwitterServer, user_name, password)
    end

    def init(state) do
        #:ets.new(:received_tweets, [:set, :named_table, :public])) #tweetid
        tweets = ["A Grouch escapes so many little annoyances that it almost pays to be one. #KinHubbard",
        "If men could get pregnant, abortion would be a sacrament!#FlorynceKennedy",
        "Admiration:  Our polite recognition of another's resemblance to ourselves.#AmbroseBierce",
        "Advertising may be described as the science of arresting human intelligence long enough to get money from it.#StephenLeacock",
        "Advertising is 85 percent confusion and 15 percent commission.#FredAllen",
        "Advertising is a valuable economic factor because it is the cheapest way of seeling goods, particularly if the goods are worthless.#SinclairLewis",
        "Advertising is legalized lying.#HGWells",
        "An alcoholic is someone you don't like who drinks as much as you do.#DylanThomas",
        "America is the greatest of opportunities and the worst of influences.#GeorgeSantayana",
        "The discovery of America was the occasion of the greatest outburst of cruelty and reckless greed known in history.#JosephConrad",
        "There is no underestimating the intelligence of the American public.#HLMencken",
        "Democracy is the are of running the circus from the monkey cage. #HLMencken",
        "Perhaps the most revolting character that the United States ever produced was the Christian business man.#HLMencken",
        "Baseball has the great advantage over cricket of being sooner ended.#GeorgeBernardShaw",
        "It ain't those parts of the Bible that I can't understand that bother me, it's the parts that I do understand.#MarkTwain",
        "So far as I can remember, there is not one word in the Gospels in praise of intelligence.#BertrandRussell",
        "The trouble with born-again Christians is that they are an even bigger pain the second time around.#HerbCaen",
        "The fact that boys are allowed to exist at all is evidence of a remarkable Christian forebearance among men.#AmbroseBierce",
        "Chess is as elaborate a waste of human intelligence as you can find outside an advertising agency.#RaymondChandler",
        "There are three terrible ages of childhood 1 to 10, 10 to 20, and 20 to 30.#ClevelandAmory",
        "A child is a curly, dimpled lunatic.#RalphWaldoEmerson",
        "If Christ were here now there is one thing he would not be A Christian.#MarkTwain",
        "Communism is like one big phone company.#LennyBruce",
        "Consistency is the last refuge of the unimaginative.#OscarWilde",
        "Convictions are more dangerous enemies of truth than lies.#Nietzsche",
        "Corporation......An ingenious device for obtaining individual profit without individual responsibility.#AmbroseBierce",
        "The power of accurate observation is commonly called cynicism by those who have not got it.#GeorgeBernardShaw",
        "Democracy encourages the majority to decide things about which the majority is blissfully ignorant.#John Simon",
        "Democracy becomes a government of bullies, barely tempered by editors",
        "One of the most common of all diseases is diagnosis.#Karl Kraus",
        "Men are born ignorant, not stupid; they are made stupid by education.#BertrandRussell",
        "Education is a method whereby one acquires a higher grade of prejudices",
        "We learn from experience that men never learn anything from experience#OscarWilde",
        "A casual stroll through the lunatic asylum shows that faith does not prove anything.#Nietzsche",
        "Always forgive your enemies. Nothing annoys them so much.#OscarWilde",
        "The only excuse for God is that he doesn't exist.#Stendhal",
        "Few things are harder to put up with than the annoyance of a good example#MarkTwain",
        "Gratitude is merely the secret hope of further favors",
        "History is a set of lies agreed upon.#NapoleonBonaparte",
        "An historian is nothing more than an unsuccessful novelist.#HLMencken",
        "History would be a wonderful thing if only it were true.#HLMencken",
        "Hope in reality is the worst of all evils, because it prolongs the torments of man#Nietzsche",
        "When a man wants to murder a tiger he calls it sport; when a tiger wants to murder him he calls it ferocity.#GeorgeBernardShaw",
        "Impiety....Your irreverence toward my deity.#AmbroseBierce",
        "Every law is and infraction of liberty.#JeremyBentham",
        "Lawyer.....One skilled in the circumvention of the law.#AmbroseBierce",
        "Liberal......A power worshipper without power.#GeorgeOrwell",
        "Liberty means responsibility; that is why most men dread it#GeorgeBernardShaw",
        "Virtue has Never been as respectable as money.#MarkTwain"]
        hashtags = ["#KinHubbard","#FlorynceKennedy","#AmbroseBierce","#StephenLeacock","#FredAllen","#SinclairLewis",
        "#HGWells","#DylanThomas","#MarleneDietrich","#GeorgeSantayana",
        "#JosephConrad","#HLMencken","#GeorgeBernardShaw","#MarkTwain",
        "#BertrandRussell","#HerbCaen","#RaymondChandler","#ClevelandAmory",
        "#RalphWaldoEmerson","#LennyBruce","#OscarWilde","#Nietzsche",
        "#John Simon","#Stendhal","#JeremyBentham","#GeorgeOrwell"]
        state = Map.put(state, :tweets, tweets)
        state = Map.put(state, :hashtags, hashtags)
        # IO.inspect state
        {:ok, state}
    end

    def update_follower_count(count, this_user) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:update, count})
    end

    def handle_cast({:update, count}, state) do
        state = Map.put(state, :xuser_follower_count, count)
        total_count = if (count == 0), do: 50, else: count * 100
        state = Map.put(state, :your_total_count, total_count)
        {:noreply, state}
    end
    #tweets can be of two categories
    # 0 - Plain tweets
    # 1 - Retweets
    def send_tweet(msg, this_user, type) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:send_tweet, msg, this_user, type})
    end

    def handle_cast({:send_tweet, msg, username, type}, state) do
        {:your_total_count, total_count} = Enum.at(state, 8)
        {:your_count, current_count} = Enum.at(state, 7)
        {:users, total_users} = Enum.at(state, 5)
        if (current_count <= total_count) do
            if (Enum.random(Enum.to_list(1..5)) == 4) do
                temp_user = Enum.random(Enum.to_list(1..total_users) -- [username])
                msg = "@#{temp_user} " <> msg
            end
            current_count = current_count + 1
            state = Map.put(state, :your_count, current_count)
            IO.puts "$#{username} : #{msg}"
            Server.send_tweet(msg, username, type)
            # {:noreply, state}
        else
            IO.puts "#{username} has reached max count of tweets."
            set_offline(username)
            {:stop, :normal, state}
            # Process.exit(:global.whereis_name(:"#{username}"), :kill)
        end
        {:noreply, state}
    end

    def receive_tweet(this_user, tweetid, message, sender) do
        # IO.puts "here for #{this_user}"
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:receive_tweet, tweetid, message, sender})
    end

    def handle_cast({:receive_tweet, tweetid, message, sender}, state) do
        {:tweetids, tweetids} = Enum.at(state, 3)
        {:users, total_users} = Enum.at(state, 5)
        tweetids = tweetids ++ [tweetid]
        state = Map.put(state, :tweetids, tweetids)
        {:name, this_user} = Enum.at(state, 1)
        #IO.inspect this_user
        tweet = "%#{sender}%" <> message
        temp_val = Enum.random(Enum.to_list(0..5))
        IO.puts "$#{this_user} : #{tweet}"
        if (Enum.random(Enum.to_list(1..5)) == 4) do
            temp_user = Enum.random(Enum.to_list(1..total_users) -- [this_user])
            tweet = "@#{temp_user} " <> tweet
        end
        if (temp_val == 0) do
            {:your_total_count, total_count} = Enum.at(state, 8)
            {:your_count, current_count} = Enum.at(state, 7)
            if (current_count <= total_count) do
                current_count = current_count + 1
                state = Map.put(state, :your_count, current_count)
                send_tweet(tweet, this_user, 1) #retweet
                {:noreply, state}
            else
                IO.puts "#{this_user} has reached max count of tweets."
                set_offline(this_user)
                {:stop, :normal, state}
                # Process.exit(:global.whereis_name(:"#{this_user}"), :kill)
            end
        end
        {:noreply, state}
    end
    #1.hashtag
    #2.mentions
    def query(this_user, query_word, type) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:query, this_user, query_word, type})
    end

    def handle_cast({:query, this_user, query_word, type}, state) do
        case type do
            1 ->
                Server.query_hashtag(query_word, this_user)
            2 ->
                Server.query_mentions(query_word, this_user)
        end
        {:noreply, state}
    end

    def set_offline(this_user) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:set_offline, this_user})
    end

    def handle_cast({:set_offline, this_user}, state) do
        IO.puts "#{this_user} is going Offline."
        Server.update_offline(this_user)
        {:noreply, state}
    end

    def set_online(this_user) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:set_online, this_user})
    end

    def handle_cast({:set_online, this_user}, state) do
        Server.update_online(this_user)
        {:noreply, state}
    end

    def get_offline_tweets(tweets, this_user) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:get_offline_tweets, tweets, this_user})
    end

    def handle_cast({:get_offline_tweets, offline_tweets, this_user}, state) do
        {:tweetids, tweetids} = Enum.at(state, 3)
        count = length(offline_tweets)
        IO.puts "#{this_user} is back Online. Number of offline tweets = #{count}"
        Enum.each(offline_tweets, fn(tweet) ->
            IO.puts "Offline tweet for $#{this_user} : #{tweet}"
        end)
        tweetids = tweetids ++ offline_tweets
        state = Map.put(state, :tweetids, tweetids)
        {:noreply, state}
    end

    def print_query(queried_tweets, query_word, this_user) do
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:print_query, queried_tweets, query_word, this_user})
    end

    def handle_cast({:print_query, tweets, query_word, this_user}, state) do
        IO.puts "#{this_user} queried for #{query_word}"
        if tweets == [] do
            IO.puts "#{query_word} for #{this_user}: No result!"
        else
            Enum.each(tweets, fn(tweet) ->
                IO.puts "#{query_word} for #{this_user}: " <> tweet
            end)
        end
        {:noreply, state}
    end

    def simulate(this_user, no_users) do
        # IO.puts "simulate for #{this_user}"
        this_pid = :global.whereis_name(:"#{this_user}")
        GenServer.cast(this_pid, {:simulate, this_user, no_users})
    end

    def handle_cast({:simulate, this_user, no_users}, state) do
        # IO.puts "handle for #{this_user}"
        range = 1..4
        list = Enum.to_list(range)
        choice = Enum.random(list)
        {:your_total_count, total_count} = Enum.at(state, 8)
        {:your_count, current_count} = Enum.at(state, 7)
        # {:xuser_follower_count, count} = Enum.at(state, 6)
        {:tweets, tweets} = Enum.at(state, 4)
        {:hashtags, hashtags} = Enum.at(state, 0)
        time = System.system_time(:millisecond)
        # IO.puts "choice #{choice}"
        if (current_count <= total_count) do
            case choice do
                1 ->
                    send_tweet(Enum.random(tweets), this_user, 0)
                    # wait_time = :math.pow((no_users - count), 2) / 100
                    # :timer.sleep(round(wait_time) * 1000)
                2 ->
                    query(this_user, Enum.random(hashtags), 1)
                3 ->
                    query(this_user, "@" <> to_string(Enum.random(Enum.to_list(1..no_users))), 2)
                4 ->
                    set_offline(this_user)
                    :timer.sleep(Enum.random(Enum.to_list(1000..5000)))
                    set_online(this_user)
            end
            simulate(this_user, no_users)
        # else
            # IO.puts "#{this_user} counts #{current_count} > #{total_count}"
        end
        {:noreply, state}
    end
end