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
        for(var i = 0; i<data.length; i++){
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
                  "<p>"+data.display_time+"</p><p>"+data.sport_name+"</p><p>"+data.skill+"</p><p>"+data.address.replaceAll(',','<br>') + "</p><p><button class='join_link button " + (inGame ? "alert'" : "success'") + " href='/" + (inGame ? ("game_attendees/"+ data.id+ "' data-method='delete'>") : "game_attendees/"+ data.id+ "' data-method='post'>")+ (inGame ? "Leave " : "Join ") + "Game</button></p>" + "<button api-endpoint='"+marker.id+"' class='view_game button primary'>View</button>";
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
