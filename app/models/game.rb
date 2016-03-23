class Game < ActiveRecord::Base
  belongs_to :creator, class_name: :User, foreign_key: :creator_id
  has_many :game_attendees, dependent: :destroy
  has_many :attendees, through: :game_attendees, source: :user, dependent: :destroy
  # before_save :add_location
  geocoded_by :location
  after_validation :geocode

  scope :future, -> { select { |x| x if x.date > Time.now }}
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

  def location
    self.address + ', ' + self.city + ', ' + self.state
  end

  def display_time
    self.date.strftime('%a %b %e, %l:%M %p')
  end
end
