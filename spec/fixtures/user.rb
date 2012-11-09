class User
  include FakeModel

  fake_columns :email, :full_name, :username
end
