namespace :sync do
  desc 'reset is new flag to false'
  task :reset => :environment do
    [User, Location, Whouse, Position, Led, LedState, PartType, Part, PartPosition, RegexCategory, Regex,Record,LocationContainer].each do |m|
      m.unscoped.update_all(is_new: false, is_dirty: false)
    end
  end
end