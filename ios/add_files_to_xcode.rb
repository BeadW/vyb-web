#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'VYB.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'VYB' }

# Find the Services group by searching all groups recursively
def find_group_by_name(group, name)
  return group if group.name == name
  group.groups.each do |subgroup|
    result = find_group_by_name(subgroup, name)
    return result if result
  end
  nil
end

services_group = find_group_by_name(project.main_group, 'Services')

if services_group.nil?
  puts "Services group not found"
  exit 1
end

puts "Found Services group: #{services_group.path}"

# Files to add
files_to_add = [
  'VYB/Services/AIDataModels.swift',
  'VYB/Services/AIProviderProtocol.swift', 
  'VYB/Services/GeminiAIProvider.swift',
  'VYB/Services/AppleIntelligenceProvider.swift',
  'VYB/Services/AIServiceManager.swift'
]

files_to_add.each do |file_path|
  file_name = File.basename(file_path)
  
  # Check if file already exists in project
  existing_file = services_group.files.find { |f| f.path == file_name }
  if existing_file
    puts "#{file_name} already exists in project"
    next
  end
  
  # Add file to group and target
  file_ref = services_group.new_reference(file_path)
  target.add_file_references([file_ref])
  
  puts "Added #{file_name} to project"
end

project.save
puts "Project saved"