class SourceRoles < ActiveRecord::Base
  include SecondDatabase
  set_table_name :roles

  def self.migrate
    all.each do |source_role|
      next if Role.find_by_name source_role.name
      puts ".. role ##{source_role.id}: #{source_role.name}"
      Role.create!(source_role.attributes) do |r|
        r.position = nil
      end
    end
  end
end
