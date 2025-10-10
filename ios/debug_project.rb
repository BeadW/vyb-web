#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'VYB.xcodeproj'

puts "Opening Xcode project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Debug: Print all groups to understand the structure
def print_groups(group, indent = 0)
  group_name = if group.respond_to?(:name)
                 group.name || group.path || 'ROOT'
               else
                 group.class.name
               end
  puts "  " * indent + "Group: #{group_name}"
  
  if group.respond_to?(:children)
    group.children.each do |child|
      if child.is_a?(Xcodeproj::Project::Object::PBXGroup) || child.class.name.include?('Group')
        print_groups(child, indent + 1)
      else
        file_name = if child.respond_to?(:name)
                      child.name || child.path
                    else
                      child.class.name
                    end
        puts "  " * (indent + 1) + "File: #{file_name}"
      end
    end
  end
end

puts "\nProject structure:"
print_groups(project.main_group)

puts "\nTargets:"
project.targets.each { |t| puts "  - #{t.name}" }