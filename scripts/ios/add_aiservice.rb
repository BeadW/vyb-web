#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = 'VYB.xcodeproj'
file_to_add = 'VYB/Services/AIService.swift'

puts "Opening Xcode project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Check if file reference already exists
file_reference_exists = project.files.find { |f| f.full_path.to_s == file_to_add }

if file_reference_exists
  puts "File reference already exists: #{file_to_add}"
else
  puts "Adding file reference: #{file_to_add}"
  
  # Navigate to the Services group
  vyb_group = project.main_group['VYB']
  if vyb_group.nil?
    puts "Error: VYB group not found!"
    exit 1
  end
  
  services_group = vyb_group['Services']
  if services_group.nil?
    puts "Error: Services group not found!"
    exit 1
  end
  
  # Create file reference
  file_reference = services_group.new_file(file_to_add)
  file_reference.path = 'AIService.swift'
  
  # Add to main target's compile sources
  main_target = project.targets.find { |t| t.name == 'VYB' }
  if main_target.nil?
    puts "Error: VYB target not found!"
    exit 1
  end
  
  main_target.source_build_phase.add_file_reference(file_reference)
  
  puts "File reference added successfully!"
end

# Save the project
project.save
puts "Project saved!"