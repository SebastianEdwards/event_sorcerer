# EventSorcerer

Generic event-sourcing scaffold.

Disclaimer: This is still a work-in-progress, is not feature complete and _is_ subject to change.

[![Code Climate](https://codeclimate.com/github/SebastianEdwards/event_sorcerer/badges/gpa.svg)](https://codeclimate.com/github/SebastianEdwards/event_sorcerer)

## What is event-sourcing?

Event-sourcing means using events as the primary source of truth for your domain models. Rather than storing the current state of your domain ala ActiveRecord or any other ORM, you append all mutating events to a log. To restore the current state of a domain object you initialize a new instance and replay the stored events against it.

## That sounds unconventional. Why would I want to do that?

Event-sourcing captures the intent of user's interacting with your system, gives you an audit log for free and allows for painless creation of new projections of your data in the future.

## New projections of your data?

Imagine replaying a domain model's events into objects that prepare it for being loaded into a relational store. Then, using those same events preparing it for a graph database or a full-text search engine. Use the right tool (read model) for the job.

## I still don't really understand...

Greg Young gave a talk on the subject which will probably explain ES concepts much better than I can. It's available here: [CQRS and Event Sourcing - Code on the Beach 2014](https://www.youtube.com/watch?v=JHGkaShoyNs).

## So what does this gem give me?

You can mixin `EventSorcerer::Aggregate` to your domain model and get a DSL for defining your events, plus an ActiveRecord-like interface for creating, finding and saving. It also gives you a unit-of-work, event-bus hooks and time-shifts your system during event replay.

## What's the catch?

This gem is like a coloring book. You get an outline but you have to color it in with your own storage engine and event bus.

## That sounds scary.

It isn't; you just need to subclass a couple of classes and implement a few methods. I'll add some examples at some point showing how to use it with a couple of different datastores.
    
## Example

Here we have a domain model representing a good ol' game of rugby. It allows the game to be started and stopped and points to be scored. Things to notice:

- Event definition is very simple. Just wrap the event methods in an `events` block. Note: as it stands in the current version your arguments must all be JSON serializable. Keyword arguments are supported.
- Validation is done with exceptions, a conceptually simple model, give invalid input and it blows up (for you to rescue and give a reasonable response to the user of course).
- Rather than keeping a current score in the database, we use events to track score-increasing events. Now, we not only know the score at any point in the game but we also know the context (the why) around the score (tries vs penalties, etc.)
- We could use fat events to allow interesting projections in the future. Fat events means storing more context than we currently need (storage is cheap!). For example we could track the scoring player for each try and create a projection which shows how many tries each player made during the entire game. We could even replay multiple games into one projection to find a player's total tally for a season.

```ruby
class RugbyGame
  class Team < Struct.new(:name, :score)
    def add_points(points)
      @score += points
    end

    def to_s
      "#{name}: #{score}"
    end
  end

  class DuplicateTeamName < RuntimeError; end
  class GameNotInProgress < RuntimeError; end
  class TeamNotPlaying < RuntimeError; end

  attr_reader :team_one
  attr_reader :team_two

  def game_in_progress?
    @game_in_progress == true
  end

  def scores
    "#{team_one} - #{team_two}"
  end

  def team_by_name(name)
    return team_one if name == team_one.name
    return team_two if name == team_two.name

    fail TeamNotPlaying
  end

  events do
    def game_started(first_team, second_team)
      fail DuplicateTeamName if first_team_name == second_team_name

      @team_one = Team.new(first_team_name,  0)
      @team_two = Team.new(second_team_name, 0)
      @game_in_progress = true

      self
    end

    def game_ended
      @game_in_progress = false

      self
    end

    def try_scored(scoring_team)
      fail GameNotInProgress unless game_in_progress?

      team_by_name(scoring_team).add_points 5

      self
    end

    def try_converted(scoring_team)
      fail GameNotInProgress unless game_in_progress?

      team_by_name(scoring_team).add_points 2

      self
    end

    def drop_goal_scored(scoring_team)
      ...
    end

    def penalty_kick_scored(scoring_team)
      ...
    end
  end
end
```

Here's how you'd use the above class:

```ruby
game = RugbyGame.new
game.game_started('All Blacks', 'Wallabies')
game.try_scored('All Blacks')
game.try_converted('All Blacks')
game.drop_goal_scored('Wallabies')

...

game.game_ended
game.scores => "All Blacks: 29 - Wallabies: 28"
game.save

... later ...
game = RugbyGame.find(6)
game.scores => "All Blacks: 29 - Wallabies: 28"
```

## Installation

Add this line to your application's Gemfile:

    gem 'event_sorcerer'

And then execute:

    $ bundle

## Contributing

1. Fork it ( http://github.com/sebastianedwards/event_sorcerer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
