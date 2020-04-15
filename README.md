# COP5615 : DISTRIBUTED SYSTEMS - Twitter-Engine

The goal of this project is to implement a Twitter Clone and a client tester/simulator. The problem statement is to implement an engine that can be paired up with WebSockets to provide full functionality. The client part (send/receive tweets) and the engine (distribute tweets) were simulated in separate OS processes.

The goal of this project is to:

Implement a Twitter like engine with the following functionality:
1. Register account
2. Send tweet. Tweets can have hashtags (e.g. #COP5615isgreat) and mentions (@bestuser)
3. Subscribe to user's tweets
4. Re-tweets (so that your subscribers get an interesting tweet you got by other means)
5. Allow querying tweets subscribed to, tweets with specific hashtags, tweets in which the user is mentioned (my mentions)
6. If the user is connected, deliver the above types of tweets live (without querying)
7. Implement a tester/simulator to test the above
8. Simulate as many users as possible
9. Simulate periods of live connection and disconnection for users
10. Simulate a Zipf distribution on the number of subscribers. For accounts with a lot of subscribers, increase the number of tweets. Make some of these messages re-tweets
11. Measure various aspects of the simulator and report performance
