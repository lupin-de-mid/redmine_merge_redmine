class SourceVersion < ActiveRecord::Base
  include SecondDatabase
  set_table_name :versions

  def self.migrate
    all.each do |source_version|
      next if RedmineMerge::Mapper.get_new_project_id(source_version.project_id).nil?
       puts "- Migrating version ##{source_version.id}"

      version = Version.create!(source_version.attributes) do |v|
        projectId = RedmineMerge::Mapper.get_new_project_id(source_version.project_id)
        v.project = Project.find(projectId) if !projectId.nil?
      end

      RedmineMerge::Mapper.add_version(source_version.id, version.id)
    end
  end
end
