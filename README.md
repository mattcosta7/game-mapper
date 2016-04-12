# Pickup Game Aggregation

---

## Installation - clone, bundle install, set env variables

1. facebook_client_id
1. facebook_client_secret
1. HOST_URL
1. gmaps_key
1. twilio\_number
1. twilio\_account\_sid
1. twilio\_auth\_token
1. twil\_ipm\_api\_key\_sid
1. twil\_ipm\_api\_key\_secret
1. twil\_ipm\_service\_sid

rake db:schema:load

rails s

localhost:3000

---

# Tutorial

## Make a new Rails app

Make a new rails project, using Postgres as the database

````
$ rails new game-aggregator --database=postgresql
$ rake db:create
$ rake db:migrate
````

Rember to git init, add and commit your project

---

## Create Users and Logins

### Gems

Create new branch, `$ git co -b add-facebook-login`

In this app, we're going to be using facebook as a means of loggin in users

To Do this we'll need to utilize omniauth.

Add these to your gemfile

```
gem 'omniauth'
gem 'omniauth-facebook'
```

### Initialize Omniauth

create a file: `config/initializers/omniauth.rb`

````
OmniAuth.config.logger = Rails.logger
Rails.application.config.middleware.use OmniAuth::Builder do
        provider :facebook, Rails.application.secrets.facebook_client_id, Rails.application.secrets.facebook_client_secret, 
          {
            info_fields: 'name,email,bio,first_name,last_name',
            display: 'popup', 
            client_options: {
              ssl: {
                ca_file: Rails.root.join("cacert.pem").to_s
              }
            }
          }
end
````

This takes care of the code necessary for omniauth to connect with facebook's login

Now, we'll need to get a facebook\_client\_id and and facebook\_client\_secret from the facebook developer portal. Store these in the "secrets.yml" file.  

Ensure this is in our .gitignore: `/config/secrets.yml`

### Create a User Model

````
rails generate model User provider uid name image token email bio first_name last_name expires_at:datetime`
rake db:migrate
````

This creates the database table to store Users with the given attributes

In the file, model/user.rb lets create a method that stores user information

````
def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider 
      user.uid      = auth.uid
      user.name     = auth.info.name
      user.email    = auth.info.email
      user.first_name = auth.info.first_name
      user.last_name  = auth.info.last_name
      user.bio = auth.info.bio
      user.phone = auth.info.phone
      user.image = auth.info.image
      user.token = auth.credentials.token
      user.expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end
````

This transforms the auth hash returned from authentication and creates an entry for a userID if it isn't created already


### User Controller

````
class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def edit
    @user = User.find params[:id]
    if @user != current_user
      redirect_to :back
    end
  end

  def show
    @user = User.find params[:id]
  end

  def update
    @user = User.find params[:id]
    if @user.update_attributes(user_params)
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def destroy
    @user = User.find params[:id]
  end

  private
  def user_params
    params.require(:user).permit(:longitude,:latitude, :location, :phone, :name, :bio, :text_reminder)
  end
end
````

rails generate controller users index edit show update destroy

create strong parameters, and define the actions.


### Handle Sessions

When a user logs in we'll need to set a session to manage that

````
rails generate controller sessions create destroy
````

edit that controller like this 

````
def create
    @user = User.from_omniauth(env["omniauth.auth"])
     session[:user_id] = @user.id
     redirect_to root_path
end
def destroy
     session[:user_id] = nil
     redirect_to root_path
end
````

When the sessions#create action is called, we return a user from omniauth, and set the session to the user id.
when the sessions#destroy action we set the session to nil

### Route it together 

````
get 'auth/:provider/callback', to: 'sessions#create'
get 'auth/failure', to: redirect('/')
get 'signout', to: 'sessions#destroy', as: 'signout'
resources :sessions, only: [:create, :destroy]
resource :home, only: [:show]
root to: "home#show"
````

The auth/:provide/callback route hits the sessions#create action, which calls the from_omniath action of our User model, setting or creating a new user.

The auth/failure route redirects to the root path, so a user can try to login again

The signout route hits the sessions#destroy action

Lastly, we need a screen to display this.   I chose a singlepage app, so use only a home#show method, and a home controller to do this.

### Login Views

Firstly, let's define a method `current_user` which we'll use to figure out if someone is signed in currently

In application_controller.rb add the following lines
````
helper_method :current_user
def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
end
````

This defines a method current_user, that returns the user if there is one, or nil if there is not. Helper Method lets us use this in views also!

Now in layout/application.html.erb file, we can add the lines

````
<% if current_user %>
  Signed in as <strong><%=current_user.image%><%= current_user.name %></strong>!
   <%= link_to "Sign out", signout_path, id: "sign_out" %> 
<% else %>
    <%= link_to "Sign in with Facebook", "/auth/facebook", id: "sign_in" %>
<% end %> 
````

This will show us a link to sign in if there is no user signed in, or that users name if there is one!

### Facebook Photo Returned

Facebook's default image size is pretty tiny, but we should be able to display other image sizes when possible, so let's make a user method for this.

````
def profile_photo(size='normal')
   "http://graph.facebook.com/#{self.uid}/picture?type=#{size}"
end
````

Now, we can call User.first.profile_photo, or User.first.profile_photo(:large), to display various sizes instead of just User.first.image, and being stuck with just one size. 

----

## Create Games

Now that we've got users, who can login and out, we'll get to the meat of the app.  
Users are able to create games, that other users can join. Once joined, users can chat with other people going to a game, and get a text message reminder an hour before the game, so that they don't forget.

### Make the Games Model

Games have some attributes, A sport, skill_level, lat, long, address, creator_id, date.

````
$ rails generate model Game sport:integer skill_level:integer lat:float long:float address:text date:datetime creator_id:integer
$ rake db:migrate
````

### Game Methods

Let's define some more methods on games
W e Currently have games and skill_levels returning only numbers, let's have that translate to words with state machines

In models/game.rb

````
scope :future, -> { select { |x| x if x.date > DateTime.now }}
scope :by_date, -> { order(:date) }
scope :sport_options, -> {sports.collect{|x| [x[:name],x[:id]] }}
scope :skill_options, -> {skills.collect{|x| [x[:name],x[:id]] }}
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
    @@skills_list[self.skill_level-1][:name]
  end

  @@sports = [
    {
      id: 1,
      name: 'Basketball',
      banner: 'basketball_banner.png'
    },
    {
      id: 2,
      name: 'Baseball',
      banner: 'basketball_banner.png'

    },
    {
      id: 3,
      name: 'Kickball',
      banner: 'kickball_banner.jpeg'
    },
    {
      id: 4,
      name: 'Hockey',
      banner: 'hockey_banner.png'
    },
    {
      id: 5,
      name: 'Soccer',
      banner: 'soccer_banner.jpg'
    }
  ]

  def self.sports
    @@sports
  end

  def sport_name
    @@sports[self.sport-1][:name]
  end

  def display_time
    self.date.strftime('%a %b %e, %l:%M %p')
  end

  def get_banner_image
    @@sports[self.sport-1][:banner]
  end
````

now we can call functions like Game.first.sport_name, or Game.first.skill to return the associated name string for displaying. 

Notice, we also defined a display_time method and a banner image method, that will help us out later!

#### Games Controller

````
class GamesController < ApplicationController

  def index
    if params[:date].present?
      time = params[:date].split('-')
      date = DateTime.new(time[0].to_i,time[1].to_i,time[2].to_i)
      @games = Game.where("DATE(date) = ? ",date).by_date
    else
      @games = Game.all.by_date.future
    end
    @game_json = []
    @games.each do |game|
      sport_name = {"sport_name" => game.sport_name}
      skill = {"skill" => game.skill}
      game = JSON::parse(game.to_json).merge(sport_name).merge(skill)
      @game_json << game
    end

    respond_to do |format|
      format.html
      format.json {render json: @game_json}
    end
  end

  def new
    @game = Game.new
  end

  def create
    @game = Game.new game_params
    if @game.save
      @game.attendees << current_user
      respond_to do |format|
        format.html {redirect_to games_path}
        format.js { render locals: {game: @game}}
      end
    else
      redirect_to :back
    end
  end

  def show
    @game = Game.find params[:id]
    display_time = {"display_time" => @game.display_time}
    attendees = {"attendees" => @game.attendees}
    sport_name = {"sport_name" => @game.sport_name}
    skill = {"skill" => @game.skill}
    cur_user = {current_user: current_user}
    @game_json = JSON::parse(@game.to_json).merge(attendees).merge(sport_name).merge(skill).merge(cur_user).merge(display_time)
    respond_to do |format|
      format.html {render layout: false}
      format.json {render json: @game_json}
    end
  end

  def edit
    @game = Game.find params[:id]
  end

  def update
    @game = Game.find params[:id]
    if @game.update_attributes(game_params)
      redirect_to :back
    else
      redirect_to :back
    end
  end

  def destroy
    @game = Game.find params[:id]
    if @game.destroy
      redirect_to games_path
    else
      redirect_to :back
    end
  end

  private
  def game_params
    params.require(:game).permit(:address, :sport, :skill_level, :date).merge(creator_id: current_user.id)
  end

end
````

This controller set is a bit more in depth, to handle more Json responses. we also merge the current_user.id to creator_id, so that every game gets immediately set as made by the logged in user.


#### Connect Games and Users

Now that we have a model and a table made for Games, we need to link them up. 

In this example, games and users have an interesting relationship.
Users have many Games they created
Games belong to a creator
Games also have Users that are attending the game

To manage this, we'll need a join table, that links users attending a game with a game.

````
rails generate model GameAttendee game_id:integer user_id:integer
rake db:migrate
````

Now that we have a table to help store our relationships, let's define them


In this example, we have a fixed set of sports and skills, so we'll define them as integers, and use a state machine to select between them

````
    User model
      has_many :games_created, foreign_key: :creator_id, class_name: :Game
      has_many :game_attendees
      has_many :games_attending, through: :game_attendees, source: :game
    Game model
      belongs_to :creator, class_name: :User, foreign_key: :creator_id
      has_many :game_attendees, dependent: :destroy
      has_many :attendees, through: :game_attendees, source: :user, dependent: :destroy
    GameAttendee model
      belongs_to :game
      belongs_to :user
````

These define active record relationships, that will allow us to query the database for 

* `User.first.games_created` (returns games the user created)
* `User.first.game_attendees` (returns the join table)
* `User.first.games_attending` (returns the array of games a user is attending)
* `Game.first.creator` (returns the creator of a game)
* `Game.first.game_attendees` (returns the join table)
* `Game.first.attendees` (returns the array of Users attending a game)

Play around in the terminal a bit, to get a feel for this 
`rails c`

### GameAttendee Controller Actions

````
  def create
    @game = Game.find params[:id]
    @game.attendees << current_user
    respond_to do |format|
      format.js
      format.html
      format.json
    end
  end

  def destroy
    @ga = GameAttendee.where(game_id: params[:id], user_id: current_user).first
    @ga.destroy
    respond_to do |format|
      format.js
      format.html
      format.json
    end
  end
````

### Form to submit a new game

Before we start this, let's install `foundation-rails` since we're building out a view, it'll be a good idea to have our frontend css framework in place.

````
gem 'foundation-rails'
````

````
$ bundle install
$ rails g foundation:install
````

This adds some files to your stylesheets which you can feel free to edit to change styling, otherwise just checkout foundation's components and use as you see fit.

With these in place, we can get to the form for submitting a new game!

````
<%= form_for @game||=Game.new, remote: true do |f| %>
  <div class="row columns">
      <%= f.label :sport %>
      <%= f.select :sport, options_for_select(Game.sport_options,selected: @game.sport) %>
  </div>
  <div class="row columns">
      <%= f.label :skill_level %>
      <%= f.select :skill_level, options_for_select(Game.skill_options, selected: @game.skill_level ) %>
  </div>
  <div class="row columns">
      <%=label_tag :date %>
      <%=text_field_tag :fake_date, nil,id: 'dp1' %>
      <%=f.hidden_field :date, id: 'real_date'%>
  </div>
  <div class="row columns" id='locationField'>
      <%= f.label :address %>
      <%= f.text_field :address, id:"autocomplete", onFocus: "geolocate()" %>
  </div>
  <% if @game.id %>
   <%= f.submit class:"button success" %>
  <%else%>
    <%= f.submit class:"button" %>
  <%end%>
<%end%>
````

utilizing select menus, and our new methods, we can get dropdown menus for sports and skills, these submit integers values corresponding to the sports and skills

There's some magic happening in the date and address fields though, so we'll go through them more indepth

#### Game Form - Date Field

HTML date fields, which you could also use aren't very pretty or user friendly. Luckily multiple libraries exist to clean them up.  

A jQuery Library built with foundation helps out with this, so instead of inputting values directly to rails, we use some jQuery/javascript to work on them first. 

install the [foundation-datepicker](https://github.com/najlepsiwebdesigner/foundation-datepicker/blob/master/js/foundation-datepicker.js) library in assets/foundation-datepicker.js 

````
$('#dp1').fdatepicker({
    initialDate: new Date(),
    format: 'mm-dd-yyyy  hh:ii',
    disableDblClickSelection: false,
    pickTime: true
  }).on('changeDate', function (event) {
    event.preventDefault();
    var date = new Date($('#dp1').val());
    $('#real_date').val(date);
  });
````

Here, we instantiate the date picker, with certain setup characteristics, and on changeDate events, we seed the hidden field from our form with the formatted date value.  fdatepicker doesn't store Dates as a date type, so this is important for consistency.

now when we submit a form, the hidden_field's info will carry through to the database, to set the appropriate date

This turns our boring datefield into something much easier to navigate, with a calendar and time selector!

### Addresses and Game Locations

To get locations from a user entered address, we'll need 2 separate processes.
  
1. To ensure that a user enters a correct address, we use Google's places api
1. Once we have this, we use the Ruby Geocoder gem to geocode the location into latitude and longitude
1. add this script to the bottom of our page where we'll display the map and add the markers

````
<script src='https://maps.googleapis.com/maps/api/js?key=<%=Rails.application.secrets.gmaps%>&libraries=places&callback=initMap'></script>
````

This will use our api key, include the places library responses, and initialize a map (which we'll setup now)

###### Map Init
Create a map.js file in assets/javascripts

````
String.prototype.replaceAll = function(search, replacement) {
    var target = this;
    return target.replace(new RegExp(search, 'g'), replacement);
};

var map,lat,long;
function initMap() {
  initAutocomplete();
  navigator.geolocation.getCurrentPosition(function(position) {
    lat = position.coords.latitude;
    long = position.coords.longitude;
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: lat, lng: long},
      scrollwheel: false,
      zoom: 13
    });
    infowindow = new google.maps.InfoWindow({
    });
    $.ajax({
      url: '/games.json'+window.location.search,
      method: 'get',
      success: function(data){
        for(var i = 0; i < data.length; i++){
          var game = data[i];
          var date = new Date(game.date);
          var options = {
              weekday: "long", year: "numeric", month: "short",
              day: "numeric", hour: "2-digit", minute: "2-digit"
          };
          var displayDate = date.toLocaleTimeString("en-us", options);
          var skill = game.skill;
          var myLatLng = {lat: game.latitude, lng: game.longitude};
          var marker = new google.maps.Marker({
              id: game.id,
              position: myLatLng,
              map: map,
              animation: google.maps.Animation.DROP,
            });
          google.maps.event.addListener(marker, 'click', (function(marker) {
            return function() {
              map.panTo(marker.getPosition());
              $.ajax({
                url: '/games/'+marker.id+'.json',
                method: 'get',
                success:function(data){
                  var inGame=false;
                  for(var i = 0; i< data.attendees.length; i++){
                    if(data.attendees[i].id === data.current_user.id){
                      inGame = true;
                      break;
                    }
                  }
                  var content =
                  "<p>"+data.display_time+"</p><p class='iw_sport_name'>"+data.sport_name+"</p><p>"+data.skill+"</p><p>"+data.address.replaceAll(',','<br>') + "</p><p><button class='join_link button " + (inGame ? "alert'" : "success'") + " href='/" + (inGame ? ("game_attendees/"+ data.id+ "' data-method='delete'>") : "game_attendees/"+ data.id+ "' data-method='post'>")+ (inGame ? "Leave " : "Join ") + "Game</button></p>" + "<button api-endpoint='"+marker.id+"' class='view_game button primary'>View</button>";
                  infowindow.setContent(content);
                  infowindow.open(map, marker);
                }
              });
            };
          })(marker));
        }
      }
    });
  });
}
````

When we load a new page, we run the init function, that setups a new map, and runs an ajax call to the games index controller, which returns the location of each marker. Those markers are all placed, and infoWidnows are setup for each to display information on clicks (pulled in from more ajax calls).

It also calls the initAutoComplete() function that initializes the form to show the autocompletion that you'll find below! 

#### Game Form - Address

Notice how we have a  function onFocus for the address field, and an id. 

This helps us autocomplete the addresses, for a faster and more correct user experience

Make a new `autocomplete.js` file in assets/javascipts, and put this there

````
var placeSearch, autocomplete;
var componentForm = {
  street_number: 'short_name',
  route: 'long_name',
  locality: 'long_name',
  administrative_area_level_1: 'short_name',
  country: 'long_name',
  postal_code: 'short_name'
};

function initAutocomplete() {
  autocomplete = new google.maps.places.Autocomplete(
      (document.getElementById('autocomplete')),
      {types: ['geocode']});

}

function geolocate() {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(function(position) {
      var geolocation = {
        lat: position.coords.latitude,
        lng: position.coords.longitude
      };
      var circle = new google.maps.Circle({
        center: geolocation,
        radius: position.coords.accuracy
      });
      autocomplete.setBounds(circle.getBounds());
    });
  }
}
````

#### Form submission

We'll be submitting this with ajax, and binding a new listener to the marker, so on submit a create.js.erb file gets served. let's create that in games views.

````
var game = {};
game.id = <%=@game.id%>;
var lat = <%=@game.latitude%>;
var lng = <%=@game.longitude%>;
var myLatLng = {lat,lng}; 
var date = new Date("<%=@game.date%>");
var options = {
    weekday: "long", year: "numeric", month: "short",
    day: "numeric", hour: "2-digit", minute: "2-digit"
};
var displayDate = date.toLocaleTimeString("en-us", options);
var sportName = "<%=@game.sport_name%>"
var link = "<a href='/games/"+game.id+"'>"+sportName+"</a>";
var skill = "<%=@game.skill%>";
var contentString = displayDate + "<br>" + link + "<br>"+ skill;
var marker = new google.maps.Marker({
  id: game.id,
  position: myLatLng,
  map: map,
  animation: google.maps.Animation.DROP
});
map.panTo(marker.getPosition());
google.maps.event.addListener(marker, 'click', (function(marker) {
  return function() {
    map.panTo(marker.getPosition());
    $.ajax({
      url: '/games/'+marker.id+'.json',
      method: 'get',
      success:function(data){
        var inGame=false;
        for(var i = 0; i< data.attendees.length; i++){
          if(data.attendees[i].id === data.current_user.id){
            inGame = true;
            break;
          }
        }
        var content =
        "<p>"+data.display_time+"</p><p>"+data.sport_name+"</p><p>"+data.skill+"</p><p>"+data.address.replaceAll(',','<br>') + "</p><p><button class='join_link button " + (inGame ? "alert'" : "success'") + " href='/" + (inGame ? ("game_attendees/"+ data.id+ "' data-method='delete'>") : "game_attendees/"+ data.id+ "' data-method='post'>")+ (inGame ? "Leave " : "Join ") + "Game</button></p>" + "<button api-endpoint='"+marker.id+"' class='view_game button primary'>View</button>";
        infowindow.setContent(content);
        infowindow.open(map, marker);
      }
    });
  };
})(marker));
makeNewChannel(sportName+"_"+game.id);
````

ignore the makeNewChannel part for now, this comes into play later on.
 
When we click submit on the form, a new game gets made, and the response js above returns, that makes a new marker, pans to it, and adds the listener for the infowindow. 

#### Map Listeners

The map listeners have buttons that link to ajax, which pulls in the details of the game, then slides up the map and shows the game.

````
  $(document).on('click','.view_game', function(){
    var that = this;
    $.ajax({
      url: '/games/'+$(that).attr('api-endpoint')+'.html',
      method: 'get',
      success:function(data){
        $('#mainsection').toggle("slide", {direction: 'up'},1000);
        setTimeout(function(){
          $('#game_detail').html(data).fadeIn(500);
          if(typeof(chatChannel) != "undefined"){
            chatChannel.leave().then(function(){
              startChannel($(that).parent('div').find('.iw_sport_name').text() + "_"+ $(that).attr('api-endpoint'));
            });
          }
          else{
            startChannel($(that).parent('div').find('.iw_sport_name').text() + "_"+ $(that).attr('api-endpoint'));
          }
          $('.games_attendees_display').ready(function(){
            $('.name-text').hide();
            $('.games_attendees_display').on('mouseenter',function(){
              $(this).find('.name-text').stop(true,true).toggle('slide',{direction: 'down'}, 1000);
            }).on('mouseleave',function(){
              $(this).find('.name-text').stop(true,true).toggle('slide',{direction: 'down'}, 1000);
            });
          });
        },1000);

      }
    });

  });

  $(document).on('click','#back',function(){
    $('.games_attendees_display').off('mouseenter','*');
    $('.games_attendees_display').off('mouseleave','*');
    $('#game_detail').off('click', '*');
    $('#game_detail').html('').fadeOut(500);
    setTimeout(function(){
      $('#mainsection').toggle("slide", {direction: 'up'},1000);
    },500);
  });
````
(with a few animations added for effect)

---

### Geocoder Gem

````
gem 'geocoder'
````

`$ bundle install`

add to game.rb

````
geocoded_by :address
after_validation :geocode

def location
  self.address + ', ' + self.city + ', ' + self.state
end
````

This is all we need to add to automatically have the long/lat changed from a submitted address, and print is effectively

---

## Twilio text setup

Ok, now our games are setup, and we've got the interactivity ironed out.   Step 2 is going to be getting text messages from the app to remind us that we need to play. 

````
gem 'twilio-ruby'
gem 'delayed_job_active_record'
gem "workless"
gem 'daemons'
````

`$ bundle install`

### Delayed Jobs 

````
rails generate delayed_job:active_record
rake db:migrate
````
then 

Set the queue_adapter in config/application.rb

````
config.active_job.queue_adapter = :delayed_job
````

this creates a table to store our 'jobs', or the hook that will send the text message once a certain time is hit.  

Delayed Jobs automates some resend trials, and other cool things.  It's pretty awesome. 

To work properly it needs daemons, and workless makes it more efficient, although we don't need to set them up at all!  Pretty sweet!

#### Twilio and DJ!

Note, go signup for Twilio We'll be using 3 APIs of theirs.  First their phone number checker, then their text messaging service, and finally their chat service. 

Once you've done that we can keep rollin.

#### DJ setup

Now, what do our jobs run on.  The texts are sent to a user, based on a game...we've already got a table for that, which is awesome.  

First, we'll define reminder, which sets the number we text from, then a client (a connection to the twilio API), message info, and creates that message.  It puts the message when called. 

We set a "Reminder Time" that allows us to edit when messages are sent, in conjunction with a when_to_run function that compares the Date an event is set for to the reminder time. 

We define this as an asynchronous function that runs at that items "when_to_run", which is set by a proc. 

Lastly, we run the :reminder method after_create, unless the user has it set to not remind them. 

````
after_create :reminder, unless: Proc.new{ !self.user.text_reminder }


@@REMINDER_TIME = 60.minutes # minutes before appointment

def reminder
  @twilio_number = Rails.application.secrets.twilio_number
  @client = Twilio::REST::Client.new Rails.application.secrets.twilio_account_sid, Rails.application.secrets.twilio_auth_token
  time_str = ((self.game.date).localtime).strftime("%I:%M%p on %b. %d, %Y")
  reminder = "#{self.user.name} you have a #{self.game.sport_name} game at #{time_str}, at #{self.game.address}. To view the game, #{ENV['HOST_URL']}games/#{self.game.id}"
  message = @client.account.messages.create(
    :from => @twilio_number,
    :to => self.user.phone,
    :body => reminder,
  )
  puts message.to
end

def when_to_run
  self.game.date - @@REMINDER_TIME
end

handle_asynchronously :reminder, :run_at => Proc.new { |i| i.when_to_run }
````

This process saves these in the Delayed::Job table, and automatically sends text to the user 1 hour before a game!

#### Check phone numbers

How do we make sure the phone number is correct?  Well, Twilio does it for us!!!

We can add a method like this onto a user, and run it before_validation

````
def phone_check
    if self.phone
      @client = Twilio::REST::LookupsClient.new Rails.application.secrets.twilio_account_sid, Rails.application.secrets.twilio_auth_token
      begin
        response = @client.phone_numbers.get(self.phone) 
        self.phone = response.phone_number
        return true
      rescue => e 
        if e.code == 20404       
          return false
        else
          raise e
        end
      end
    end
  end
````

If a user has a phone number, we check to see if it's real via twilios service, and update as necessary from their service (which automatically fills in some details for us!)  It's pretty cool!

#### Twilio Chat

Finally, our user's probably want to talk with eachother before the game, to get psyched up.  let's give them an avenue to do that. 

Twilio offers a great service for this, in their *FREE!* IP messaging service

To start, we'll need some information from our server that interacts with twilio's api.

`rails generate controller tokens`

edit that file to include

````
class TokensController < ApplicationController
  before_filter :authenticate! 
  def create
    token = get_token
    grant = get_grant
    token.add_grant(grant)
    render json: {username: current_user.name, token: token.to_jwt}
  end
  def get_token
    Twilio::Util::AccessToken.new(
      Rails.application.secrets.twilio_account_sid,
      Rails.application.secrets.twil_ipm_api_key_sid,
      Rails.application.secrets.twil_ipm_api_key_secret,
      3600, 
      current_user.name
    )
  end
  def get_grant 
    grant = Twilio::Util::AccessToken::IpMessagingGrant.new 
    grant.endpoint_id = "Chatty:#{current_user.name.gsub(" ", "_")}:browser"
    grant.service_sid = Rails.application.secrets.twil_ipm_service_sid
    grant
  end
  private 
  def authenticate!
    if !current_user
      redirect_to root_path
    end
  end
end
````

This will 1, ensure there's a user, 2 create some tokens and grants that twilio needs to function securely. From this, we go right to the javascripts needed by twilio

when the page lands that displays the messenger, an ajax call to our token controller is made that sets up the user in a channel (note how one of these functions is already in the ajax return when a new game is made, creating that channel) 

Twilio Setup

````
function startChannel(name){
    var name = name;
    var username;
    var channel;
    function printMessage(message) {
      $('#messages').append(message + "<br>");
      $('#messages').scrollTop($('#messages')[0].scrollHeight);
    }
    function printDate(timestamp){
        var dd = timestamp.getDate();
        var yyyy = timestamp.getFullYear();
        var mo = timestamp.getMonth()  + 1;
        var hours = timestamp.getHours();
        var mins = timestamp.getMinutes(); 
        return mo+'/'+dd+'/'+yyyy+" "+hours+":"+mins      
    }
    function setupChannel() {
        chatChannel.join().then(function(channel) {
            chatChannel.getMessages(20).then(function(messages) {
              var totalMessages = messages.length;
              for (i=0; i<messages.length; i++) {
                var message = messages[i];
                printMessage("<span class='message_author'>"+message.author+"</span>" + ' @ '+"<span class='message_date'>"+printDate(message.timestamp)+"</span>"+': ' + "<span class='message_body'>"+message.body+"</span>");
              }
              console.log('Total Messages:' + totalMessages);
            });
        });
        chatChannel.on('messageAdded', function(message) {
            printMessage(message.author + ": " + message.body);
         });
    }
    var $input = $('#chat-input'); 
    $input.on('keydown', function(e) {
        if (e.keyCode == 13) {
            chatChannel.sendMessage($input.val())
            $input.val('');
        }
     });
    if($('.messenger').length>0){
        requestTokenFromServer(name);
    }
    function requestTokenFromServer(name){
        $.post("/tokens", function(data) {
            username = data.username;
            var accessManager = new Twilio.AccessManager(data.token);
            var messagingClient = new Twilio.IPMessaging.Client(accessManager);
            messagingClient.getChannelByUniqueName(name).then(function(channel) {
                if (channel) {
                    chatChannel = channel;
                    setupChannel();
                } else {
                    messagingClient.createChannel({
                        uniqueName: name,
                        friendlyName: name + " Chat" 
                    })
                    .then(function(channel) {
                        chatChannel = channel;
                        setupChannel();
                    });
                }
            });
        });
    }
    function makeNewChannel(name){
        requestTokenFromServer(name)
    };
}
````

---

This handles all of the events, details and creation associated with the channels!  Each game has a separate channel for users to interact with eachother! 

A channel gets setup if it isn't already, which has a user join that channel.
Then we get the last 20 messages, print them in order, scrolling to the bottom of the div everytime a message is printed.   

When a message is added in the chat, the messageAdded event is found, and the message is printed. When the message is sent, it gets added to the channel. 

Now I've left out some of the fabric that links things together, but please go through the code, and see where things lie.   

---

# resources

1. [Rails](http://guides.rubyonrails.org/)
1. [OmniAuth-Facebook](https://github.com/mkdynamic/omniauth-facebook)
1. [foundation-rails](https://github.com/zurb/foundation-rails)
1. [foundation-datepicker](https://github.com/najlepsiwebdesigner/foundation-datepicker/blob/master/js/foundation-datepicker.js)
1. [google maps api](https://developers.google.com/maps/documentation/javascript/)
1. [google autocomplete](https://developers.google.com/maps/documentation/javascript/examples/places-autocomplete)
1. [twilio phone lookup](https://www.twilio.com/docs/api/lookups)
1. [twilio sms](https://www.twilio.com/sms/api)
1. [twilio ipm](https://www.twilio.com/blog/2016/02/add-chat-to-a-rails-app-with-twilio-ip-messaging.html)
1. [delayed job](https://github.com/collectiveidea/delayed_job)