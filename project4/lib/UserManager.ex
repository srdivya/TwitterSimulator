defmodule UserManager do
    use GenServer
    def start_link(no_users) do
        GenServer.start_link(__MODULE__,%{tweets: [], hashtags: [], no_users: no_users} ,[name: :UserManagerProcess])
        {:ok, ifs} = :inet.getif()
        ips = for {ip, _, _} <- ifs, do: to_string(:inet.ntoa(ip))
        this_ip = Enum.at(ips,Enum.count(ips)-1)#to_string(hd(ips))
        client_name =  "client@" <> this_ip
        Node.start(:"#{client_name}")
        Node.set_cookie :sugar
        server_name = "server@" <> this_ip
        Node.connect (:"#{server_name}")
        spawn_users(no_users, no_users)
        simulate_twitter(no_users, no_users)
        :timer.sleep(:infinity)
        # send_tweet(:UserManagerProcess)
        # query_hashtag(:UserManagerProcess)
        # query_mentions(:UserManagerProcess)
        # set_offline(:UserManagerProcess)
        #if (ret_atom == :spawned_users)
    end

    def simulate_twitter(no_users, this_user) do
        if this_user > 0 do
            # IO.puts "this = #{this_user}"
            Client.simulate(this_user, no_users)
            simulate_twitter(no_users, this_user - 1)
        end
    end

    def init(state) do
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
        
        {:ok, state}
    end
    
    def spawn_users(no_users, total_users) do
        if no_users > 0 do
            Client.start_link(no_users, no_users, total_users)
            spawn_users(no_users - 1, total_users)
        end
        :spawned_users
    end

    # def send_tweet(pid) do
    #     GenServer.cast(:UserManagerProcess, :send_tweet)
    #     # set_offline(no_users)
    #     send_tweet(:UserManagerProcess)
    #     # simulate_twitter(no_users)
    # end

    # def handle_cast(:send_tweet, state) do
    #     # IO.puts "here"
    #     # IO.inspect state
    #     {:no_users, no_users} = Enum.at(state,1)
    #     {:tweets, tweets} = Enum.at(state, 2)
    #     {:hashtags, hashtags} = Enum.at(state, 0)
    #     # {:hashtags, hashtags} = Enum.at(state, 0)
    #     user = Enum.random(Enum.to_list(1..no_users))
    #     tweet = Enum.random(tweets)
    #     # IO.puts "user#{user} tweet is #{tweet}"
    #     Client.send_tweet(tweet, user, 0)

    #     Client.query(user, Enum.random(hashtags), 1) #hashtag
    #     Client.query(user, "@" <> to_string(Enum.random(Enum.to_list(1..no_users))), 2) #mentions
    #     # send_tweet(:UserManagerProcess)
    #     # query_hashtag(:UserManagerProcess)
    #     # query_mentions(:UserManagerProcess)
    #     # set_offline(:UserManagerProcess)
    #     # simulate_twitter(no_users)
    #     #IO.puts "after"
    #     {:noreply, state}
    # end

    # def query_hashtag(pid) do
    #     GenServer.cast(:UserManagerProcess, :query_hashtag)
    #     # query_hashtag(:UserManagerProcess)
    # end

    # def handle_cast(:query_hashtag, state) do
    #     {:no_users, no_users} = Enum.at(state,1)
    #     {:hashtags, hashtags} = Enum.at(state, 0)
    #     user = Enum.random(Enum.to_list(1..no_users))
    #     Client.query(user, Enum.random(hashtags), 1) #hashtag
    #     {:noreply, state}
    # end

    # def query_mentions(pid) do
    #     GenServer.cast(:UserManagerProcess, :query_mentions)
    #     # query_mentions(:UserManagerProcess)
    # end

    # def handle_cast(:query_mentions, state) do
    #     {:no_users, no_users} = Enum.at(state,1)
    #     user = Enum.random(Enum.to_list(1..no_users))
    #     Client.query(user, "@" <> to_string(Enum.random(Enum.to_list(1..no_users))), 2) #mentions
    # end
    
    # def set_offline(pid) do
    #     # IO.inspect (Process.whereis(:UserManagerProcess))
    #     # IO.puts "setoffline #{no_users}"
    #     GenServer.cast(:UserManagerProcess, :set_offline)
    #     # set_offline(:UserManagerProcess)
    # end

    # def handle_cast(:set_offline, state) do
    #     IO.puts "here"
    #     {:no_users, no_users} = Enum.at(state,1)
    #     user = Enum.random(Enum.to_list(1..no_users))
    #     Client.set_offline(user)
    #     :timer.sleep(Enum.random(Enum.to_list(1..10000)))
    #     Client.set_online(user)
    #     # set_offline(no_users)
    #     {:noreply, state}
    # end
end