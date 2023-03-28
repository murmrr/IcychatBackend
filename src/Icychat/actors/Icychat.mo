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

import AssetMap "AssetMap";

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
import AddPushTokenError "../types/AddPushTokenError";
import LeaveChatError "../types/LeaveChatError";
import GhostAccountError "../types/GhostAccountError";
import RemovePushTokenError "../types/RemovePushTokenError";
import StableBuffer "../types/StableBuffer";
import StableHashMap "../types/FunctionalStableHashMap";

actor Icychat {

  let ONESIGNAL_APP_ID : Text = "19d49feb-ac2c-494c-9f7c-d8392c73d838";
  let ONESIGNAL_REST_API_KEY : Text = "OTc2YmMxNzMtMzZkMi00MmI2LWJhZDYtYzQ0MTI5NzlkMzM1";

  stable var allChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init<Chat.Chat>();
  stable var userToPushTokens : StableHashMap.StableHashMap<Principal, StableHashMap.StableHashMap<Text, Text>> = StableHashMap.init<Principal, StableHashMap.StableHashMap<Text, Text>>();
  stable var userToPublicKey : StableHashMap.StableHashMap<Principal, Text> = StableHashMap.init<Principal, Text>();
  stable var userToProfile : StableHashMap.StableHashMap<Principal, Profile.Profile> = StableHashMap.init<Principal, Profile.Profile>();
  stable var userToChats : StableHashMap.StableHashMap<Principal, StableBuffer.StableBuffer<Chat.Chat>> = StableHashMap.init<Principal, StableBuffer.StableBuffer<Chat.Chat>>();

  public shared query (msg) func isRegistered() : async Bool {
    switch (StableHashMap.get(userToPushTokens, Principal.equal, Principal.hash, msg.caller)) {
      case null {
        return false;
      };

      case (?value) {
        return true;
      }
    };
  };

  public shared query (msg) func getUsers(searchQuery : Text) : async Result.Result<[Principal], GetUsersError.GetUsersError> {
    let chats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (chats) {
      case (?chats) {

        if (searchQuery == "") {
          return #ok([]);
        };

        let allUsers : [Principal] = Iter.toArray(StableHashMap.keys(userToProfile));

        func f1(p : Principal) : Bool = not Principal.equal(p, msg.caller);
        let withoutCaller : [Principal] = Array.filter(allUsers, f1);

        let searchPattern : Text.Pattern = #text(searchQuery);
        func f2(p : Principal) : Bool = switch (StableHashMap.get(userToProfile, Principal.equal, Principal.hash, p)) {
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
    let value : ?Text.Text = StableHashMap.get(userToPublicKey, Principal.equal, Principal.hash, userPrincipal);
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
    let value : ?Profile.Profile = StableHashMap.get(userToProfile, Principal.equal, Principal.hash, userPrincipal);
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
    let value : ?Profile.Profile = StableHashMap.get(userToProfile, Principal.equal, Principal.hash, msg.caller);
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
    let value : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        let temp : Buffer.Buffer<ChatHeader.ChatHeader> = Buffer.Buffer<ChatHeader.ChatHeader>(0);
        for (chat in StableBuffer.vals(value)) {
          temp.add(ChatHeader.construct(msg.caller, chat));
        };
        return #ok(temp.toArray());
      };
    };
  };

  public shared query (msg) func getMyChat(id : Nat) : async Result.Result<SharedChat.SharedChat, GetMyChatError.GetMyChatError> {
    let value : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        for (chat in StableBuffer.vals(value)) {
          if (chat.id == id) {
            return #ok(SharedChat.construct(msg.caller, chat));
          };
        };
        return #err(#IdNotFound);
      };
    };
  };

  public shared (msg) func addPushToken(id : Text, pushToken : Text) : async Result.Result<(), AddPushTokenError.AddPushTokenError> {
    let value : ?StableHashMap.StableHashMap<Text, Text> = StableHashMap.get(userToPushTokens, Principal.equal, Principal.hash, msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        let pushTokens : StableHashMap.StableHashMap<Text, Text> = StableHashMap.init<Text, Text>();
        StableHashMap.put(pushTokens, Text.equal, Text.hash, id, pushToken);
        StableHashMap.put(userToPushTokens, Principal.equal, Principal.hash, msg.caller, pushTokens);

        return #ok();
      };
    };
  };

  public shared (msg) func removePushToken(id : Text) : async Result.Result<(), RemovePushTokenError.RemovePushTokenError> {
    let value : ?StableHashMap.StableHashMap<Text, Text> = StableHashMap.get(userToPushTokens, Principal.equal, Principal.hash, msg.caller);
    switch (value) {
      case null {
        return #err(#UserNotFound);
      };

      case (?value) {
        StableHashMap.delete(value, Text.equal, Text.hash, id);

        return #ok();
      };
    };
  };

  public shared (msg) func register(profileUpdate : ProfileUpdate.ProfileUpdate, publicKey : Text) : async Result.Result<(), RegisterError.RegisterError> {
    if (not ProfileUpdate.validate(profileUpdate)) {
      return #err(#InvalidProfile);
    };

    let value : ?Profile.Profile = StableHashMap.get(userToProfile, Principal.equal, Principal.hash, msg.caller);
    switch (value) {
      case (?value) {
        return #err(#AlreadyRegistered);
      };

      case null {
        Cycles.add(500000000000); //TODO set appropriate amount of cycles
        let newAssetMap : AssetMap.AssetMap = await AssetMap.AssetMap(msg.caller);
        let newPortalPrincipal : Principal = Principal.fromActor(newAssetMap);

        let initialProfile : Profile.Profile = Profile.getDefault(msg.caller, newAssetMap);
        let profile : Profile.Profile = Profile.update(initialProfile, profileUpdate);
        StableHashMap.put(userToPushTokens, Principal.equal, Principal.hash, msg.caller, StableHashMap.init<Text, Text>());
        StableHashMap.put(userToPublicKey, Principal.equal, Principal.hash, msg.caller, publicKey);
        StableHashMap.put(userToProfile, Principal.equal, Principal.hash, msg.caller, profile);
        StableHashMap.put(userToChats, Principal.equal, Principal.hash, msg.caller, StableBuffer.init<Chat.Chat>());
        return #ok();
      };
    };
  };

  public shared (msg) func ghostAccount() : async Result.Result<(), GhostAccountError.GhostAccountError> {
    switch (StableHashMap.get(userToProfile, Principal.equal, Principal.hash, msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?a) {
        StableHashMap.delete(userToPushTokens, Principal.equal, Principal.hash, msg.caller);
      };
    };

    return #ok();
  };

  public shared (msg) func burnAccount() : async Result.Result<(), BurnAccountError.BurnAccountError> {
    switch (StableHashMap.get(userToProfile, Principal.equal, Principal.hash, msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?a) {
        StableHashMap.delete(userToPublicKey, Principal.equal, Principal.hash, msg.caller);
        StableHashMap.delete(userToPublicKey, Principal.equal, Principal.hash, msg.caller);
        StableHashMap.delete(userToProfile, Principal.equal, Principal.hash, msg.caller);

        switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller)) {
          case null {
            return #err(#UserNotFound);
          };

          case (?chats) {
            for (chat in StableBuffer.vals(chats)) {
              StableHashMap.delete(chat.keys, Principal.equal, Principal.hash, msg.caller);
              if (StableBuffer.size(chat.users) > 2) {
                let newUsers : StableBuffer.StableBuffer<Principal> = StableBuffer.init<Principal>();
                for (user in StableBuffer.vals(chat.users)) {
                  if (user != msg.caller) {
                    StableBuffer.add(newUsers, user);
                  };
                };
                StableBuffer.clear(chat.users);
                StableBuffer.append(chat.users, newUsers);
              } else {
                if (StableBuffer.get(chat.users, 0) == msg.caller) {
                  switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, StableBuffer.get(chat.users, 1))) {
                    case null {
                      return #err(#UserNotFound);
                    };

                    case (?otherChats) {
                      let newChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init<Chat.Chat>();
                      for (otherChat in StableBuffer.vals(otherChats)) {
                        if (otherChat.id != chat.id) {
                          StableBuffer.add(newChats, otherChat);
                        };
                      };
                      StableBuffer.clear(otherChats);
                      StableBuffer.append(otherChats, newChats);
                    };
                  };

                } else {
                  switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, StableBuffer.get(chat.users, 0))) {
                    case null {
                      return #err(#UserNotFound);
                    };

                    case (?otherChats) {
                      let newChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init<Chat.Chat>();
                      for (otherChat in StableBuffer.vals(otherChats)) {
                        if (otherChat.id != chat.id) {
                          StableBuffer.add(newChats, otherChat);
                        };
                      };
                      StableBuffer.clear(otherChats);
                      StableBuffer.append(otherChats, newChats);
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    StableHashMap.delete(userToChats, Principal.equal, Principal.hash, msg.caller);

    return #ok();
  };

  public shared (msg) func createChat(otherUser : Principal, myKey : Text, otherUserKey : Text) : async Result.Result<(), CreateChatError.CreateChatError> {
    let myChats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        let otherChats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, otherUser);
        switch (otherChats) {
          case null {
            return #err(#UserNotFound);
          };

          case (?otherChats) {
            let seed : Blob = await Random.blob();
            let chat : Chat.Chat = Chat.construct(seed, msg.caller, otherUser, myKey, otherUserKey);

            StableBuffer.add(allChats, chat);

            StableBuffer.add(myChats, chat);
            StableBuffer.add(otherChats, chat);

            return #ok();
          };
        };
      };
    };
  };

  public shared (msg) func leaveChat(id : Nat) : async Result.Result<(), LeaveChatError.LeaveChatError> {
    switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller)) {
      case null {
        return #err(#UserNotFound);
      };

      case (?chats) {
        for (chat in StableBuffer.vals(chats)) {
          if (chat.id == id) {
            if (StableBuffer.size(chat.users) > 2) {
              StableHashMap.delete(chat.keys, Principal.equal, Principal.hash, msg.caller);

              let newUsers : StableBuffer.StableBuffer<Principal> = StableBuffer.init<Principal>();
              for (user in StableBuffer.vals(chat.users)) {
                if (user != msg.caller) {
                  StableBuffer.add(newUsers, user);
                };
              };
              StableBuffer.clear(chat.users);
              StableBuffer.append(chat.users, newUsers);
            } else {
              if (StableBuffer.get(chat.users, 0) == msg.caller) {
                switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, StableBuffer.get(chat.users, 1))) {
                  case null {
                    return #err(#UserNotFound);
                  };

                  case (?otherChats) {
                    let otherNewChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init<Chat.Chat>();
                    for (chat in StableBuffer.vals(otherChats)) {
                      if (chat.id != id) {
                        StableBuffer.add(otherNewChats, chat);
                      };
                    };
                    StableBuffer.clear(otherChats);
                    StableBuffer.append(otherChats, otherNewChats);
                  };
                };
              } else {
                switch (StableHashMap.get(userToChats, Principal.equal, Principal.hash, StableBuffer.get(chat.users, 0))) {
                  case null {
                    return #err(#UserNotFound);
                  };

                  case (?otherChats) {
                    let otherNewChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init();
                    for (chat in StableBuffer.vals(otherChats)) {
                      if (chat.id != id) {
                        StableBuffer.add(otherNewChats, chat);
                      };
                    };
                    StableBuffer.clear(otherChats);
                    StableBuffer.append(otherChats, otherNewChats);
                  };
                };
              };
            };
          };

          let myNewChats : StableBuffer.StableBuffer<Chat.Chat> = StableBuffer.init<Chat.Chat>();
          for (chat in StableBuffer.vals(chats)) {
            if (chat.id != id) {
              StableBuffer.add(myNewChats, chat);
            };
          };
          StableBuffer.clear(chats);
          StableBuffer.append(chats, myNewChats);

          return #ok();
        };
        return #err(#IdNotFound);
      };
    };
  };

  public shared (msg) func addToChat(id : Nat, otherUser : Principal, otherUserKey : Text) : async Result.Result<(), AddToChatError.AddToChatError> {
    let myChats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        let otherChats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, otherUser);
        switch (otherChats) {
          case null {
            return #err(#UserNotFound);
          };

          case (?otherChats) {

            for (myCurrentChat in StableBuffer.vals(myChats)) {
              if (myCurrentChat.id == id) {

                func f(p : Principal) : Bool = Principal.equal(p, otherUser);
                if (Array.find(StableBuffer.toArray(myCurrentChat.users), f) != null) {
                  return #err(#UserAlreadyInChat);
                };

                StableHashMap.put(myCurrentChat.keys, Principal.equal, Principal.hash, otherUser, otherUserKey);
                StableBuffer.add(myCurrentChat.users, otherUser);
                StableBuffer.add(otherChats, myCurrentChat);

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
    let myChats : ?StableBuffer.StableBuffer<Chat.Chat> = StableHashMap.get(userToChats, Principal.equal, Principal.hash, msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        for (myCurrentChat in StableBuffer.vals(myChats)) {
          if (myCurrentChat.id == id) {
            let seed : Blob = await Random.blob();
            let message : Message.Message = Message.construct(seed, msg.caller, content);

            StableBuffer.add(myCurrentChat.messages, message);

            func f1(idx : Nat) : Text = switch (StableHashMap.get(userToProfile, Principal.equal, Principal.hash, StableBuffer.toArray(myCurrentChat.users)[idx])) {
              case null {
                return "";
              };

              case (?value) {
                return value.username;
              };
            };
            var usernames : [Text] = Array.tabulate(Iter.size(StableBuffer.toArray(myCurrentChat.users).vals()), f1);
            if (StableBuffer.size(myCurrentChat.users) == 2) {
              switch (StableHashMap.get(userToProfile, Principal.equal, Principal.hash, msg.caller)) {
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
            let withoutCaller : [Principal] = Array.filter(StableBuffer.toArray(myCurrentChat.users), f2);

            let includePlayerIds : Buffer.Buffer<JSON.JSON> = Buffer.Buffer(0);
            for (user in withoutCaller.vals()) {
              switch (StableHashMap.get(userToPushTokens, Principal.equal, Principal.hash, user)) {
                case null {};

                case (?value) {
                  for (pushToken in StableHashMap.vals(value)) {
                    includePlayerIds.add(#String(pushToken));
                  };

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
