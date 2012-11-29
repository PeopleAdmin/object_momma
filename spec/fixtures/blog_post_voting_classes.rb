File.dirname(__FILE__).tap do |current_directory|
  %w{fake_model post user comment vote}.each do |file|
    require File.join(current_directory, file)
  end
end

class VoteBuilder < ObjectMomma::Builder
  has_siblings :comment, :voter => :user
  child_id { "#{voter}'s #{vote_type} for #{comment}" }

  def first_or_initialize
    Vote.where({
      comment_id: comment.id,
      user_id:    voter.id,
      type:       vote_type.downcase
    })
  end

  def decorate(vote)
    # The regular Vote class doesn't implement this method, but Vote objects
    # instantiated via ObjectMomma will get this behavior. Be careful with
    # this feature, it can make a mess!
    def vote.switch_vote!
      if upvote?
        self.type = 'downvote'
      else
        self.type = 'upvote'
      end
    end
  end
  
  def build!(vote)
    # This is demonstration only. In a real ActiveRecord scenario, that
    # scope returned by #first_or_initialize would have set this stuff for
    # us. It may be possible to automatically do this in a generic way.
    vote.comment = self.comment
    vote.type    = self.vote_type
    vote.user    = self.voter

    # This is basic "set my data according to who I am" logic:
    if vote.user.politician?
      vote.switch_vote!
    end

    vote.save!
  end
end

module ObjectMomma
  class UserBuilder < Builder
    def first_or_initialize
      User.where(email: test_email)
    end

    def decorate!(user)
      def user.politician?
        full_name == "John Adams"
      end
    end

    def build!(user, attributes = {})
      # ActiveRecord's scope returned by #first_or_initialize would do this for
      # us under normal circumstances.
      user.email     = attributes[:email]    || test_email
      user.username  = attributes[:username] || test_username
      user.full_name = child_id

      user.save!
    end

  private

    # A child id of 'Scott Pilgrim' becomes 'scottpilgrim@zz.zzz'
    def test_email
      "#{test_username}@zz.zzz"
    end

    # A child id of 'Scott Pilgrim' becomes 'scottpilgrim'
    def test_username
      self.child_id.split(' ', 2).map(&:downcase).join
    end
  end

  class PostBuilder < Builder
    child_id { "Post about #{subject}" }

    def first_or_initialize
      Post.where(title: title_from_subject)
    end

    def build!(post)
      post.title   = title_from_subject
      post.subject = self.subject
      post.body    = body_from_subject

      post.save!
    end

  private

    def body_from_subject
      case self.subject
      when "Comic Books" then "Batman is the best comic book of all time"
      when "Politics" then "John Adams was a great leader."
      else "Lorem Ipsum"
      end
    end

    def title_from_subject
      case self.subject
      when "Comic Books" then "Batman"
      else "My Thoughts on #{self.subject}"
      end
    end
  end

  class CommentBuilder < Builder
    has_siblings :post, :author => :user
    child_id { "#{author}'s Comment on #{post}" }

    def first_or_initialize
      Comment.where({
        post_id: post.id,
        user_id: author.id
      })
    end

    def build!(comment)
      comment.post = self.post
      comment.user = self.author

      comment.save!
    end
  end
end
