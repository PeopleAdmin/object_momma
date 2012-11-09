class Comment
  include FakeModel

  belongs_to :post
  belongs_to :user

  fake_column :text
end
