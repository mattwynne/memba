Let's brainstorm about this membership system for the KMC.

Let's talk about the problems that the KMC has.

Primarily, what they need is a database that lists all of the members past and present. With information like their date of birth, a phone number, an address, and their membership status, and their date when they last renewed and when their membership is going to expire.

We also need a way for them to pay for membership, ideally a recurring billing. And we need a way for them to express relationships. So you can have, for example, one adult in a family who joins the KMC and then gets membership and manages the membership for their partner, their wife, or husband, and their kids so it needs to be possible for the member to manage that group.

From a membership secretary's point of view, I think it'd be helpful if it's possible to just get that list synchronized to a Google Doc spreadsheet. I think that would be helpful.

Also, then we get into being able to contact the members. So being able to blast out an announcement email to all members seems like a very useful capability. And then allowing members to see content on a website that is only visible to active members. So you can only access that information if you're an active member.

Maybe we have a funnel, so you can also just sign up that's interested in joining one day and join the newsletter so you can get a funnel.

So we've got renewals, we've got the list of members, and as a member I should be able to browse the directory of other members. And then we've got email broadcasts from a small number of people, should be given the right to blast an email to all of the members. And then there's an announcement.

And then we need members to be able to contact each other. So that could be just sharing your email address, but what we are used to right now is that there's an email list, kind of like a channel-like Discourse or something, so it's possible for me to send an email to a particular address, and that is then emailed out to all of the members. And that needs to be reliable, it needs to work for all of the different email providers like Hotmail, and we probably need to test that because we've had problems with that recently.

And then the other factor that would be really cool would be to be able to manage activities. So, at the Kootenay Mountaineering Club we run trips really regularly, there's probably 150 trips a year, and a trip has a description, it has a leader, or perhaps multiple leaders, it has participants, they can express an interest and then the trip leader can add them to the trip, and it has a date when it's going to happen, and that's probably enough for the basics of a trip, allowing people to see who else has signed up, and then potentially those trips can be also published on the website.

And a puzzle I have with this app is, I think I want to use AT Protocol because I think I want this idea of membership of the club to be kind of social. I'm part of my social profile, I'm in this club, I'm in that club, and I have a hunch that this should be part of the AT Protocol network, the ability to be in a club and communicate with other members of the club.

But I have puzzles around how much of the information that goes on in a member club needs to be private and how much needs to be public, what will people want to keep private, what will they be comfortable with being public, this AT Protocol is kind of a social media platform, also around tenanting, so my idea is that multiple clubs like the KMC will be able to use this system.

I guess one day I imagine it also having a mobile app, would that system have a separate PDS instance per club, would it be able to have one big PDS for the whole app, and then we somehow segment the users by club within that, I'm not clear about that.

I don't know about the trade offs, and I also don't know what technology to build in because I think the default implementation of a PDS from Bluesky is written in TypeScript, should we write the whole thing in TypeScript, maybe we should, what does that allow for mobile apps.

And then the other question is kind of rollout strategy and MVP, but all this stuff with trips is icing on the cake, we don't have that now, but the sort of MVP I think is around a membership list, a private website, membership renewals, members directory and member relationships, and probably a bit of authorization roles type stuff. And once we have that, then we can actually decommission the old website and move people over.

So that feels like the MVP and the trip stuff is an addition on top, and does that even need AT Protocol or is it good to start with it from the beginning, I'm not sure.

I really kind of want to use Elixir Phoenix because I just really like that. It's a platform, I love it, it works great, it feels like a really robust place to go with tech. But how compatible is that with the rest of the stack that I'd be wanting to use with AT Protocol and what else?

And so like going to phones, how possible is it to take an Elixir backend and surface it on iOS and Android?

There you go, I think those are my thoughts. I think we're going to call it Memba, M-E-M-B-A, I think I can register the memba.io domain, yeah.
