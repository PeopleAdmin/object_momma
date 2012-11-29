require 'object_momma'
require File.join(File.dirname(__FILE__), 'fixtures/blog_post_voting_classes')

describe ObjectMomma do
  before do
    User.destroy_all
    Post.destroy_all
    Comment.destroy_all
    Vote.destroy_all
  end

  let(:vote_child_id) do
    "Billy Pilgrim's Upvote for Scott Pilgrim's Comment on Post about Comic Books"
  end

  context "A simple object type (User)" do
    shared_examples_for "Scott Pilgrim" do
      it("is a User") { user.should be_a(User) }
      it("has its' email set properly") { user.email.should == "scottpilgrim@zz.zzz" }
      it("has its' username set properly") { user.username.should == "scottpilgrim" }
      it("is persisted") { user ; ObjectMomma.find_user("Scott Pilgrim") }
    end

    context "when instantiated with a Hash" do
      let(:user) { ObjectMomma.spawn_user(child_id: "Scott Pilgrim") }
      it_behaves_like "Scott Pilgrim"
    end

    context "when instantiated with a String" do
      let(:user) { ObjectMomma.spawn_user("Scott Pilgrim") }
      it_behaves_like "Scott Pilgrim"
    end
  end

  context "An object type that has a child id constructor (Post)" do
    shared_examples_for "Post about Comic Books" do
      it("is a Post") { post.should be_a(Post) }
      it("has its' title set properly") { post.title.should == "Batman" }
      it("has its' subject set properly") { post.subject.should == "Comic Books" }
      it("is persisted") { post ; ObjectMomma.find_post("Post about Comic Books") }
    end
    
    context "when instantiated with a Hash" do
      let(:post) { ObjectMomma.spawn_post(subject: "Comic Books") }
      it_behaves_like "Post about Comic Books"
    end

    context "when instantiated with a String" do
      let(:post) { ObjectMomma.spawn_post("Post about Comic Books") }
      it_behaves_like "Post about Comic Books"
    end
  end

  context "An object with simple siblings (Comment)" do
    shared_examples_for "Scott Pilgrim's Comment on Post about Comic Books" do
      it("is a Comment") { comment.should be_a(Comment) }
      it("has its' user set properly") do
        comment.user.object_id.should == ObjectMomma.find_user("Scott Pilgrim").object_id
      end
      it("has its' post set properly") do
        comment.post.object_id.should == ObjectMomma.find_post("Post about Comic Books").object_id
      end
      it("is persisted") do
        comment
        ObjectMomma.find_comment("Scott Pilgrim's Comment on Post about Comic Books")
      end
    end
    
    context "when instantiated with a Hash" do
      let(:comment) do
        ObjectMomma.spawn_comment({
          author: "Scott Pilgrim",
          post:   "Post about Comic Books"
        })
      end
      it_behaves_like "Scott Pilgrim's Comment on Post about Comic Books"
    end

    context "when instantiated with a String" do
      let(:comment) do
        ObjectMomma.spawn_comment("Scott Pilgrim's Comment on Post about Comic Books")
      end
      it_behaves_like "Scott Pilgrim's Comment on Post about Comic Books"
    end
  end

  context "An object with nested siblings (Vote)" do
    context "when instantiated with a String" do
      let(:vote) do
        ObjectMomma.spawn_vote(vote_child_id)
      end
      it("is a Vote") { vote.should be_a(Vote) }
      it("has its' user set properly") do
        vote.user.object_id.should == ObjectMomma.find_user("Billy Pilgrim").object_id
      end
      it("has its' comment set properly") do
        vote.comment.object_id.should == ObjectMomma.find_comment("Scott Pilgrim's Comment on Post about Comic Books").object_id
      end
    end
  end

  context "An object with serialized attributes" do
    before do
      ObjectMomma.use_serialized_attributes  = true
      ObjectMomma.serialized_attributes_path = File.expand_path("../fixtures", __FILE__)
    end

    after do
      ObjectMomma.use_serialized_attributes  = false
    end

    let(:user) { ObjectMomma.spawn_user("Scott Pilgrim") }

    it "pulls in the attributes and loads them into the object" do
      user.email.should    == "foobar@zz.zzz"
      user.username.should == "lovemuscle23"
    end
  end

  context "An object whose builder is stored in the builder path" do
    after do
      ObjectMomma.builder_path = nil
    end

    it "Loads the builder ruby file from the path only after builder path is set" do
      lambda {
        ObjectMomma.spawn_thing("The Thing")
      }.should raise_error(NoMethodError)

      ObjectMomma.builder_path = File.expand_path("../fixtures", __FILE__)

      thing = ObjectMomma.spawn_thing("The Thing")

      thing.a_property.should       == :foo
      thing.another_property.should == :bar
    end
  end

  context ".spawn" do
    it "invokes #spawn_(object_type) for the supplied arguments" do
      ObjectMomma.should_receive(:spawn_user).with("Billy Pilgrim").once
      ObjectMomma.should_receive(:spawn_user).with("Scott Pilgrim").once
      ObjectMomma.should_receive(:spawn_vote).with(vote_child_id).once
      ObjectMomma.should_receive(:spawn_comment).with("Post about Politics").once

      ObjectMomma.spawn({
        users: ["Billy Pilgrim", "Scott Pilgrim"],
        vote: vote_child_id,
        comment: "Post about Politics"
      })
    end
  end

  context ".spawn_(object_type)" do
    it "raises an ObjectMomma::BadChildIdentifier when it cannot parse child id" do
      lambda {
        ObjectMomma.spawn_post("Poast about Birds")
      }.should raise_error(ObjectMomma::BadChildIdentifier)
    end
  end

  context ".mullet!" do
    before do
      ObjectMomma.mullet!
    end

    after do
      if Object.const_defined?(:ObjectMother)
        Object.send(:remove_const, :ObjectMother)
      end
    end

    it "defines ObjectMother" do
      Object.const_defined?(:ObjectMother).should be_true
    end

    it "delegates everything to ObjectMomma" do
      ObjectMomma.should_receive(:fizzle).with(:shizzle)
      ObjectMother.fizzle(:shizzle)
    end
  end

  context ".find_(object_type)" do
    it "raises an ObjectMomma::ObjectNotFound exception when object does not exist" do
      lambda {
        ObjectMomma.find_user("Scott Pilgrim")
      }.should raise_error(ObjectMomma::ObjectNotFound)
    end

    it "does not raise an ObjectMomma::ObjectNotFound exception when object does exist" do
      ObjectMomma.spawn_user("Scott Pilgrim")
      lambda {
        ObjectMomma.find_user("Scott Pilgrim")
      }.should_not raise_error(ObjectMomma::ObjectNotFound)
    end
  end

  context ".create_(object_type)" do
    it "does not raise an ObjectMomma::ObjectExists exception when object does not exist" do
      lambda {
        ObjectMomma.create_user("Scott Pilgrim")
      }.should_not raise_error(ObjectMomma::ObjectExists)
    end

    it "raises an ObjectMomma::ObjectExists exception when object does exist" do
      ObjectMomma.spawn_user("Scott Pilgrim")
      lambda {
        ObjectMomma.create_user("Scott Pilgrim")
      }.should raise_error(ObjectMomma::ObjectExists)
    end
  end

  context ".(object_type)" do
    it "creates objects that don't exist, and finds objects that do" do
      lambda {
        ObjectMomma.user("Scott Pilgrim")
      }.should_not raise_error(ObjectMomma::ObjectNotFound)
      lambda {
        ObjectMomma.user("Scott Pilgrim")
      }.should_not raise_error(ObjectMomma::ObjectExists)
    end
  end

  context ".(object_type)_attributes" do
    before { ObjectMomma.use_serialized_attributes = true }
    after  { ObjectMomma.use_serialized_attributes = false }

    it "returns a symbolized hash from the yml file corresponding to the object type" do
      ObjectMomma.user_attributes("Scott Pilgrim").should == {
        email:    "foobar@zz.zzz",
        id:       3,
        username: "lovemuscle23"
      }
    end
  end
end
