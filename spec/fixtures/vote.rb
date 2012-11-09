class Vote
  include FakeModel

  belongs_to :comment
  belongs_to :user

  fake_column :type

  def downvote?
    type == 'downvote'
  end

  def upvote?
    type == 'upvote'
  end
end
