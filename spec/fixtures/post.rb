class Post
  include FakeModel

  fake_columns :body, :subject, :title
end
