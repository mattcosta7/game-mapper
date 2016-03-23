class Game < ActiveRecord::Base
  @@skills_list = [
    {
      id: 1,
      name: 'Beginner'
    },
    {
      id: 2,
      name: 'Intermediate'
    },
    {
      id: 3,
      name: 'Advanced'
    },
    {
      id: 4,
      name: 'We Wish We Were Pro'
    }
  ]

  def self.skills
    @@skills_list
  end

  def skill
    @@skills_list[self.skill_level][:name]
  end

  @@sports = [
    {
      id: 1,
      name: 'Basketball'
    },
    {
      id: 2,
      name: 'Baseball'
    },
    {
      id: 3,
      name: 'Kickball'
    },
    {
      id: 4,
      name: 'Hockey'
    },
    {
      id: 5,
      name: 'Soccer'
    },
    {
      id: 6,
      name: 'Hockey'
    }
  ]

  def self.sports
    @@sports
  end

  def sport_name
    @@sports[self.sport][:name]
  end

end
