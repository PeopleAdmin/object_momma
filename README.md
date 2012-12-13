# ObjectMomma

An Object Mother implementation in ruby

## Description

ObjectMomma is a gem that implements the Object Mother pattern for managing test data. It shares a lot of goals with FactoryGirl, but represents a fundamentally different approach.  See [this article by Martin Fowler](http://martinfowler.com/bliki/ObjectMother.html) for more information.

## Vs. Fixtures and Factories

The Object Mother pattern shares some benefits with fixtures -- namely, by assigning fixed names (I call them *child identifiers*) to the objects you define, you can mentally associate the properties of each object with those names. For instance, the user called "Joe Spammer" may be used pervasively throughout tests that cover comment moderation. You can even build larger scenarios that can be re-used over and over by your team.

However, unlike fixtures, instead of managing yml files that directly manipulate database state, you can build out your objects in ruby with all of your model behaviors available. In this way, you get some of the best benefits of both fixtures and traditional factories.

The biggest benefit of Object Mother over both fixtures and factories is that they are not tied to ActiveRecord, so you can actually use ObjectMomma to refactor your entire model structure if you need to. ObjectMomma's goal is to facilitate data set up for your acceptance tests, not unit tests, so there is no reason that you couldn't use ObjectMomma alongside FactoryGirl or fixtures. This approach is similar to using cucumber for acceptance tests and rspec or Test::Unit for your unit/controller tests.

## Installation

Install the gem locally:

    gem install object_momma

Or add it to your Gemfile:

    gem 'object_momma'

and run `bundle install` from your shell.

## Usage

### How your spec should look

`rspec/capybara`:

    feature "Moderating comments" do
      let(:post) do
        ObjectMomma.post("Birds")
       end
       
      background do
        ObjectMomma.spawn_comment("Joe Schmoe's Comment on the Post about Birds")
      end
      
      scenario "Up voting a comment" do
        visit post_path(post)
        # etc.
      end
    end

`Test::Unit`:

    class CommentModeration < ActionController::IntegrationTest
      def setup
        @post = ObjectMomma.post("Birds")
        ObjectMomma.spawn_post("Joe Schmoe's Comment on the Post About Birds")
      end
      
      def test_upvoting_a_comment
        visit post_path(post)
        # etc.
      end
    end

### Using ObjectMomma

To create new objects, use methods that start with `ObjectMomma.spawn_*`, e.g. `ObjectMomma.spawn_user`:

    => user = ObjectMomma.spawn_user("Joe Schmoe")
    -> <#User:0xdeadbeef>

In this case above, "Joe Schmoe" can be thought of as the *child identifier* for the particular child we're creating.
 
Some objects are composed of other objects, and they can actually nest those child identifiers neatly, e.g. `Joe Schmoe's Comment on the Post about Birds.` You can spawn them by either referring to their composite child identifier, or by a hash mapping the associated object names to their identifiers:

    => comment = ObjectMomma.spawn_comment("Joe Schmoe's Comment on the Post about Birds")
    => comment = ObjectMomma.spawn_comment(user: "Joe Schmoe", post: "Birds")

`ObjectMomma.create_*` will raise an `ObjectMomma::ObjectExists` exception if the object has already been spawned.

    => ObjectMomma.create_user("Joe Schmoe") # Works the first time
    => ObjectMomma.create_user("Joe Schmoe") # Now raises an ObjectExists exception
    => ObjectMomma.spawn_user("Joe Schmoe")  # Works fine :)
    => ObjectMomma.user("Joe Schmoe")

If you want to raise an error if the object *doesn't* exist, then `ObjectMomma.find_*` will raise an `ObjectMomma::ObjectNotFound` exception in that case:

    => ObjectMomma.find_user("Joe Schmoe")  # Raises ObjectNotFound exception
    => ObjectMomma.spawn_user("Joe Schmoe") # Works fine :)
    => ObjectMomma.find_user("Joe Schmoe")  # Does not raise exception

You can also build a bunch of objects all at once with `ObjectMomma.spawn`:

    => ObjectMomma.spawn({
         posts:   ["Birds", "Middle Earth", "Sports"],
         users:   ["Joe Schmoe", "Scott Pilgrim"],
         comment: "Billy Pilgrim's Comment on Post about Cooking"
       })

The idea with the single call to `ObjectMomma.spawn` is to be able to encapsulate complicated data setup with a simple, semantic call.

### Teaching ObjectMomma how to build new types of objects

The examples above assumed that ObjectMomma knew how to build out the objects in question. To actually teach ObjectMomma how to build the objects, consider:

In `spec/object_momma/user.rb`:

    class ObjectMomma::UserBuilder < ObjectMomma::Builder
      def first_or_initialize
        User.where(full_name: self.child_id)
      end
      
      def build!(user)
        user.full_name = child.child_id
      end
    end
    
The method `#first_or_initialize` has the most important role of the builder: it grabs the object from the persistence layer if it exists, otherwise, it initializes a new object.

After grabbing an object from `#first_or_initialize`, ObjectMomma will invoke `#build!` if and only if the object hasn't yet been persisted. `#build!` will actually set up the data and persist the object itself.

#### Composed Builders

You can also implement builders that know how to compose objects from their associated objects:

    class ObjectMomma::CommentBuilder < ObjectMomma::Builder
      child_id { "#{author}'s Comment on #{post}" }
      has_siblings :post, author: user
      
      def first_or_initialize
        Comment.where(user_id: self.author.id, post_id: self.post.id)
      end
      
      def build!(object)
        if object.user.spammer?
          object.text = "Check out teh cheap pillz from mycheappillz.com!!!"
        elsif object.post.subject == :birds
          # etc. …
        end
      end
    end

It is important to note the distinction between `self` and `object` in these cases.  `self` refers to the builder which has been hydrated with properties from the `child_id` block, whereas `object` refers to the child object itself.

### But I don't *want* to use ActiveRecord!

The only requirement ObjectMomma imposes on the objects that are spawned via your `first_or_initialize` methods is that they respond to `#persisted?` the way ActiveRecord objects do.  The gem itself does not depend on ActiveRecord at all; feel free to use whatever persistence layer you want. Consider overriding `ObjectMomma::Builder.is_persisted?` if your objects don't respond to `#persisted?`.

Your builder's `first_or_initialize` method can return a Scope, as well. ObjectMomma will simply call `first_or_initialize` for you.

### Serialized Attributes

Supplying all the fictional data for your different children can be tedious and ugly. You may want to store canned attributes for your objects in YAML files, similar to fixtures. This features is completely optional. The attributes will get passed to your builders' #build! method as the second argument. An empty hash will be supplied if ObjectMomma couldn't find and parse the attributes for you. Example:

    # spec/object_momma/user_builder.rb
    class ObjectMomma::UserBuilder
      …
      
      def build!(user, attributes)
        user.attributes = attributes
      end
      
      …
    end

The YAML file:

    # spec/object_momma/attributes/users.yml
    Scott Pilgrim:
      username: "scott_pilgrim"
      email:    "spilgrim@zz.zzz"

To use:

    => ObjectMother.spawn("Scott Pilgrim")
    -> #<User:0xdeadbeef @username="scott_pilgrim", @email="spilgrim@zz.zzz", …>

### Business in the front, party in the back

If you'd like to refer to ObjectMomma via the constant ObjectMother, then have it your way:

In `spec/spec_helper.rb`, add `ObjectMomma.mullet!` somewhere.  Then:

    => ObjectMother.spawn_user("Joe Dirt")

## More Information

 * [ObjectMomma by Martin Fowler](http://martinfowler.com/bliki/ObjectMother.html)

### Credits

ObjectMomma was written by Nathan Ladd, with help from a few partners in crime:

 * Josh Flanagan (jflanagan on github)
 * Theo Mills

And, of course, I read about the ObjectMother pattern that I ~~ruined~~ implemented from:

 * Martin Fowler
