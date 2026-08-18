class AddUserToQueries < ActiveRecord::Migration[8.1]
  def change
    add_reference :queries, :user, foreign_key: true, null: true
  end
end
