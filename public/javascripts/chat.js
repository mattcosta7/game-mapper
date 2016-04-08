function startChannel(name){
    var name = name;
    var username;
    var channel;

    function printMessage(message) {
      $('#messages').append(message + "<br>");
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
            chatChannel.getMessages().then(function(messages) {
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