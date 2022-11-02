import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import JSON "mo:json/JSON";
import Nat "mo:base/Nat";
import UUID "mo:uuid/UUID";
import Source "mo:uuid/Source";
import AsyncSource "mo:uuid/async/SourceV4";
import XorShift "mo:rand/XorShift";
import Cycles "mo:base/ExperimentalCycles";

import RegisterError "../types/RegisterError";
import BurnAccountError "../types/BurnAccountError";
import ProfileUpdate "../types/ProfileUpdate";
import Profile "../types/Profile";
import CreateChatError "../types/CreateChatError";
import Chat "../types/Chat";
import GetProfileError "../types/GetProfileError";
import MessageContent "../types/MessageContent";
import SendMessageError "../types/SendMessageError";
import Message "../types/Message";
import GetMyChatHeadersError "../types/GetMyChatHeadersError";
import SharedChat "../types/SharedChat";
import GetMyProfileError "../types/GetMyProfileError";
import ChatHeader "../types/ChatHeader";
import GetMyChatError "../types/GetMyChatError";
import GetUsersError "../types/GetUsersError";
import AddToChatError "../types/AddToChatError";
import GetPublicKeyError "../types/GetPublicKeyError";
import GetMyChatKeyError "../types/GetMyChatKeyError";
import HttpTypes "../types/HttpTypes";
import SetMyPushTokenError "../types/SetMyPushTokenError";
import LeaveChatError "../types/LeaveChatError";
import GetMyPushTokenError "../types/GetMyPushTokenError";
import GhostAccountError "../types/GhostAccountError";

actor Icychat {

  let ONESIGNAL_APP_ID : Text = "19d49feb-ac2c-494c-9f7c-d8392c73d838";
  let ONESIGNAL_REST_API_KEY : Text = "OTc2YmMxNzMtMzZkMi00MmI2LWJhZDYtYzQ0MTI5NzlkMzM1";

  var allChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
  var userToPushToken : HashMap.HashMap<Principal, Text> = HashMap.HashMap(0, Principal.equal, Principal.hash);
  var userToPublicKey : HashMap.HashMap<Principal, Text> = HashMap.HashMap(0, Principal.equal, Principal.hash);
  var userToProfile : HashMap.HashMap<Principal, Profile.Profile> = HashMap.HashMap(0, Principal.equal, Principal.hash);
  var userToChats : HashMap.HashMap<Principal, Buffer.Buffer<Chat.Chat>> = HashMap.HashMap(0, Principal.equal, Principal.hash);

  public shared query (msg) func getUsers(searchQuery : Text) : async Result.Result<[Principal], GetUsersError.GetUsersError> {
    let chats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (chats) {
      case (?chats) {

        if (searchQuery == "") {
          return #ok([]);
        };

        let allUsers : [Principal] = Iter.toArray(userToProfile.keys());

        func f1(p : Principal) : Bool = not Principal.equal(p, msg.caller);
        let withoutCaller : [Principal] = Array.filter(allUsers, f1);

        let searchPattern : Text.Pattern = #text(searchQuery);
        func f2(p : Principal) : Bool = switch (userToProfile.get(p)) {
          case null {
            return false;
          };
          case (?profile) {
            if (Text.contains(profile.username, searchPattern)) {
              return true;
            } else {
              return false;
            };
          };
        };
        let filtered : [Principal] = Array.filter(withoutCaller, f2);

        return #ok(filtered);
      };

      case null {
        return #err(#UserNotFound);
      };
    };
  };

  public shared query func getPublicKey(userPrincipal : Principal) : async Result.Result<Text, GetPublicKeyError.GetPublicKeyError> {
    let value : ?Text.Text = userToPublicKey.get(userPrincipal);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        return #ok(value);
      };
    };
  };

  public shared query func getProfile(userPrincipal : Principal) : async Result.Result<Profile.Profile, GetProfileError.GetProfileError> {
    let value : ?Profile.Profile = userToProfile.get(userPrincipal);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        return #ok(value);
      };
    };
  };

  public shared query (msg) func getMyProfile() : async Result.Result<Profile.Profile, GetMyProfileError.GetMyProfileError> {
    let value : ?Profile.Profile = userToProfile.get(msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        return #ok(value);
      };
    };
  };

  public shared query (msg) func getMyChatHeaders() : async Result.Result<[ChatHeader.ChatHeader], GetMyChatHeadersError.GetMyChatHeadersError> {
    let value : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        let temp : Buffer.Buffer<ChatHeader.ChatHeader> = Buffer.Buffer<ChatHeader.ChatHeader>(0);
        for (chat in value.vals()) {
          temp.add(ChatHeader.construct(msg.caller, chat));
        };
        return #ok(temp.toArray());
      };
    };
  };

  public shared query (msg) func getMyChat(id : Nat) : async Result.Result<SharedChat.SharedChat, GetMyChatError.GetMyChatError> {
    let value : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        for (chat in value.vals()) {
          if (chat.id == id) {
            return #ok(SharedChat.construct(msg.caller, chat));
          };
        };
        return #err(#IdNotFound);
      };
    };
  };

  public shared query (msg) func getMyPushToken() : async Result.Result<Text, GetMyPushTokenError.GetMyPushTokenError> {
    let value : ?Profile.Profile = userToProfile.get(msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?profile) {
        switch (userToPushToken.get(msg.caller)) {
          case null {
            return #ok("");
          };

          case (?value) {
            return #ok(value);
          };
        };
      };
    };
  };

  public shared (msg) func setMyPushToken(pushToken : Text) : async Result.Result<(), SetMyPushTokenError.SetMyPushTokenError> {
    let value : ?Profile.Profile = userToProfile.get(msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        userToPushToken.put(msg.caller, pushToken);

        return #ok();
      };
    };
  };

  public shared (msg) func register(profileUpdate : ProfileUpdate.ProfileUpdate, publicKey : Text) : async Result.Result<(), RegisterError.RegisterError> {
    if (not ProfileUpdate.validate(profileUpdate)) {
      return #err(#InvalidProfile);
    };

    let value : ?Profile.Profile = userToProfile.get(msg.caller);
    switch (value) {
      case (?value) {
        return #err(#AlreadyRegistered);
      };

      case null {
        let initialProfile : Profile.Profile = Profile.getDefault(msg.caller);
        let profile : Profile.Profile = Profile.update(initialProfile, profileUpdate);
        userToPublicKey.put(msg.caller, publicKey);
        userToProfile.put(msg.caller, profile);
        userToChats.put(msg.caller, Buffer.Buffer<Chat.Chat>(0));
        return #ok();
      };
    };
  };

  public shared (msg) func ghostAccount() : async Result.Result<(), GhostAccountError.GhostAccountError> {
    switch (userToProfile.get(msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?a) {
        userToPushToken.delete(msg.caller);
      };
    };

    return #ok();
  };

  public shared (msg) func burnAccount() : async Result.Result<(), BurnAccountError.BurnAccountError> {
    switch (userToProfile.get(msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?a) {
        userToPublicKey.delete(msg.caller);
        userToPublicKey.delete(msg.caller);
        userToProfile.delete(msg.caller);

        switch (userToChats.get(msg.caller)) {
          case null {
            return #err(#UserNotFound);
          };

          case (?chats) {
            for (chat in chats.vals()) {
              chat.keys.delete(msg.caller);
              if (chat.users.size() > 2) {
                let newUsers : Buffer.Buffer<Principal> = Buffer.Buffer(0);
                for (user in chat.users.vals()) {
                  if (user != msg.caller) {
                    newUsers.add(user);
                  };
                };
                chat.users.clear();
                chat.users.append(newUsers);
              } else {
                if (chat.users.get(0) == msg.caller) {
                  switch (userToChats.get(chat.users.get(1))) {
                    case null {
                      return #err(#UserNotFound);
                    };

                    case (?otherChats) {
                      let newChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
                      for (otherChat in otherChats.vals()) {
                        if (otherChat.id != chat.id) {
                          newChats.add(otherChat);
                        };
                      };
                      otherChats.clear();
                      otherChats.append(newChats);
                    };
                  };

                } else {
                  switch (userToChats.get(chat.users.get(0))) {
                    case null {
                      return #err(#UserNotFound);
                    };

                    case (?otherChats) {
                      let newChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
                      for (otherChat in otherChats.vals()) {
                        if (otherChat.id != chat.id) {
                          newChats.add(otherChat);
                        };
                      };
                      otherChats.clear();
                      otherChats.append(newChats);
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    userToChats.delete(msg.caller);

    return #ok();
  };

  public shared (msg) func createChat(otherUser : Principal, myKey : Text, otherUserKey : Text) : async Result.Result<(), CreateChatError.CreateChatError> {
    let myChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        let otherChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(otherUser);
        switch (otherChats) {
          case null {
            return #err(#UserNotFound);
          };

          case (?otherChats) {
            for (chat in myChats.vals()) {
              if (chat.users.size() == 2) {
                func f(p : Principal) : Bool = Principal.equal(p, otherUser);
                if (Array.find(chat.users.toArray(), f) != null) {
                  return #err(#ChatAlreadyExists);
                };
              };
            };
            for (chat in otherChats.vals()) {
              if (chat.users.size() == 2) {
                func f(p : Principal) : Bool = Principal.equal(p, msg.caller);
                if (Array.find(chat.users.toArray(), f) != null) {
                  return #err(#ChatAlreadyExists);
                };
              };
            };

            let seed : Blob = await Random.blob();
            let chat : Chat.Chat = Chat.construct(seed, msg.caller, otherUser, myKey, otherUserKey);

            allChats.add(chat);

            myChats.add(chat);
            otherChats.add(chat);

            return #ok();
          };
        };
      };
    };
  };

  public shared (msg) func leaveChat(id : Nat) : async Result.Result<(), LeaveChatError.LeaveChatError> {
    switch (userToChats.get(msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?chats) {
        for (chat in chats.vals()) {
          if (chat.id == id) {
            if (chat.users.size() > 2) {
              chat.keys.delete(msg.caller);

              let newUsers : Buffer.Buffer<Principal> = Buffer.Buffer(0);
              for (user in chat.users.vals()) {
                if (user != msg.caller) {
                  newUsers.add(user);
                };
              };
              chat.users.clear();
              chat.users.append(newUsers);
            } else {
              if (chat.users.get(0) == msg.caller) {
                switch (userToChats.get(chat.users.get(1))) {
                  case null {
                    return #err(#UserNotFound);
                  };

                  case (?otherChats) {
                    let otherNewChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
                    for (chat in otherChats.vals()) {
                      if (chat.id != id) {
                        otherNewChats.add(chat);
                      };
                    };
                    otherChats.clear();
                    otherChats.append(otherNewChats);
                  };
                };
              } else {
                switch (userToChats.get(chat.users.get(0))) {
                  case null {
                    return #err(#UserNotFound);
                  };

                  case (?otherChats) {
                    let otherNewChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
                    for (chat in otherChats.vals()) {
                      if (chat.id != id) {
                        otherNewChats.add(chat);
                      };
                    };
                    otherChats.clear();
                    otherChats.append(otherNewChats);
                  };
                };
              };
            };
          };

          let myNewChats : Buffer.Buffer<Chat.Chat> = Buffer.Buffer(0);
          for (chat in chats.vals()) {
            if (chat.id != id) {
              myNewChats.add(chat);
            };
          };
          chats.clear();
          chats.append(myNewChats);

          return #ok();
        };
        return #err(#IdNotFound);
      };
    };
  };

  public shared (msg) func addToChat(id : Nat, otherUser : Principal, otherUserKey : Text) : async Result.Result<(), AddToChatError.AddToChatError> {
    let myChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        let otherChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(otherUser);
        switch (otherChats) {
          case null {
            return #err(#UserNotFound);
          };

          case (?otherChats) {

            for (myCurrentChat in myChats.vals()) {
              if (myCurrentChat.id == id) {

                func f(p : Principal) : Bool = Principal.equal(p, otherUser);
                if (Array.find(myCurrentChat.users.toArray(), f) != null) {
                  return #err(#UserAlreadyInChat);
                };

                myCurrentChat.keys.put(otherUser, otherUserKey);
                myCurrentChat.users.add(otherUser);
                otherChats.add(myCurrentChat);

                return #ok();
              };
            };
            return #err(#IdNotFound);
          };
        };
      };
    };
  };

  public shared (msg) func sendMessage(id : Nat, content : MessageContent.MessageContent) : async Result.Result<SharedChat.SharedChat, SendMessageError.SendMessageError> {
    let myChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        for (myCurrentChat in myChats.vals()) {
          if (myCurrentChat.id == id) {
            let seed : Blob = await Random.blob();
            let message : Message.Message = Message.construct(seed, msg.caller, content);

            myCurrentChat.messages.add(message);

            func f1(idx : Nat) : Text = switch (userToProfile.get(myCurrentChat.users.toArray()[idx])) {
              case null {
                return "";
              };

              case (?value) {
                return value.username;
              };
            };
            var usernames : [Text] = Array.tabulate(Iter.size(myCurrentChat.users.toArray().vals()), f1);
            if (myCurrentChat.users.size() == 2) {
              switch (userToProfile.get(msg.caller)) {
                case null {
                  return #err(#UserNotFound);
                };

                case (?value) {
                  usernames := [value.username];
                };
              };
            };
            let title : Text = Text.join(", ", usernames.vals());

            func f2(p : Principal) : Bool = not Principal.equal(p, msg.caller);
            let withoutCaller : [Principal] = Array.filter(myCurrentChat.users.toArray(), f2);

            let includePlayerIds : Buffer.Buffer<JSON.JSON> = Buffer.Buffer(0);
            for (user in withoutCaller.vals()) {
              switch (userToPushToken.get(user)) {
                case null {};

                case (?value) {
                  includePlayerIds.add(#String(value));
                };
              };
            };

            let url0 : Text = "https://onesignal.com/api/v1/notifications";

            let headers0 : [HttpTypes.HttpHeader] = [
              { name = "Content-Type"; value = "application/json" },
              {
                name = "Authorization";
                value = Text.concat("Basic ", ONESIGNAL_REST_API_KEY);
              },
            ];

            let externalId : Text = UUID.toText(await AsyncSource.Source().new());
            let bodyMap : HashMap.HashMap<Text, JSON.JSON> = HashMap.HashMap(0, Text.equal, Text.hash);
            bodyMap.put("app_id", #String(ONESIGNAL_APP_ID));
            bodyMap.put("external_id", #String(externalId));
            bodyMap.put("include_player_ids", #Array(includePlayerIds.toArray()));
            let contentsMap : HashMap.HashMap<Text, JSON.JSON> = HashMap.HashMap(0, Text.equal, Text.hash);
            contentsMap.put("en", #String("New Message"));
            bodyMap.put("contents", #Object(contentsMap));
            let headingsMap : HashMap.HashMap<Text, JSON.JSON> = HashMap.HashMap(0, Text.equal, Text.hash);
            headingsMap.put("en", #String(title));
            bodyMap.put("headings", #Object(headingsMap));
            let body0 : JSON.JSON = #Object(bodyMap);

            let request : HttpTypes.CanisterHttpRequestArgs = {
              url = url0;
              max_response_bytes = ?0;
              headers = headers0;
              body = ?Blob.toArray(Text.encodeUtf8(JSON.show(body0)));
              method = #post;
              transform = null;
            };
            try {
              Cycles.add(500_000_000);
              let ic : HttpTypes.IC = actor ("aaaaa-aa");
              let response : HttpTypes.CanisterHttpResponsePayload = await ic.http_request(request);
            } catch (err) {};

            return #ok(SharedChat.construct(msg.caller, myCurrentChat));
          };
        };
        return #err(#IdNotFound);
      };
    };
  };
};
