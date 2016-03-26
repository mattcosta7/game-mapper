var map,lat,long;
function initMap() {
  navigator.geolocation.getCurrentPosition(function(position) {
    lat = position.coords.latitude;
    long = position.coords.longitude;
    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: lat, lng: long},
      scrollwheel: false,
      zoom: 11
    });
    $.ajax({
      url: '/games.json'+window.location.search,
      method: 'get',
      success: function(data){
        playData = data;
        for(var i = 0; i<data.length; i++){
          var game = data[i]
          var date = new Date(game.date);
          var options = {
              weekday: "long", year: "numeric", month: "short",
              day: "numeric", hour: "2-digit", minute: "2-digit"
          };
          var displayDate = date.toLocaleTimeString("en-us", options);
          var link = "<a href='/games/"+game.id+"'>"+game.sport_name+"</a>";
          var skill = game.skill;
          var contentString = displayDate + "<br>" + link + "<br>"+ skill;
          infowindow = new google.maps.InfoWindow({
          });
          var myLatLng = {lat: game.latitude, lng: game.longitude};
          var marker = new google.maps.Marker({
              id: game.id,
              position: myLatLng,
              map: map,
              title: game.sport_name,
              animation: google.maps.Animation.DROP,
              content: contentString
            });
          google.maps.event.addListener(marker, 'click', (function(marker) {  
            return function() {   
               infowindow.setContent(marker.content);  
               infowindow.open(map, marker);
               $.ajax({
                url: '/games/'+marker.id+'.json',
                method: 'get',
                success:function(data){
                  var inGame=false;
                  for(var i = 0; i< data.attendees.length; i++){
                    if(data.attendees[i].id == data.current_user.id){
                      inGame = true
                      break;
                    }
                  }
                  content = 
                  "<div class='row'><div class='small-6 large-6 columns'><a href='/" + (inGame ? "game_attendees/" : "join/")+data.id+"'data-method='delete''>"+ (inGame ? "Leave " : "Join ") + "Game</a><p>"+data.sport_name+"</p><p>"+data.skill+"</p><p>"+data.address + "</p><p>"+data.city+"</p><p>"+data.state+ "</p></div>";
                  var holder = document.getElementById('game-detail');
                  holder.innerHTML = content;
                  if(data.attendees.length > 0){
                    content += "<div class='small-6 large-6 columns'><ul>Attendees";
                    for(var i = 0; i<data.attendees.length; i++){
                      var person = data.attendees[i]
                      content += "<li>"+"<a href='/users/"+person.id+"'><img src='"+person.image+"'>"+person.name+"</a></li>";
                    }
                    content += "</ul></div></div>"
                    holder.innerHTML = content;
                  }
                  else{
                    holder.innerHTML += "<p>No One Attending Yet, be the first</p>"
                  }
                }
              })  
            }  
          })(marker));  
        } 
      }
    })
  })
}