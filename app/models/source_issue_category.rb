class SourceIssueCategory < ActiveRecord::Base
  include SecondDatabase
  set_table_name :issue_categories

  def self.migrate
    all.each do |source_issue_category|
      next if IssueCategory.find_by_name_and_project_id(source_issue_category.name, source_issue_category.project_id)
      puts "- Migrating ##{source_issue_category.id}"
      IssueCategory.create!(source_issue_category.attributes) do |ic|
        projectId = RedmineMerge::Mapper.get_new_project_id(source_issue_category.project_id)
        ic.project = Project.find(projectId) if !projectId.nil?
      end
    end
  end
end
