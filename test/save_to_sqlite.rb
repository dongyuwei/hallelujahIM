require 'sequel'
require 'json'

DB = Sequel.connect('sqlite://translation.sqlite.db')

DB.create_table :translation do
  primary_key :key
  String :key
  String :value
end

translation = DB[:translation]



data = JSON.parse(File.open('all_translation.json','r').read);

data.each do|key, value|
    translation.insert(:key => key, :value => value)
end
