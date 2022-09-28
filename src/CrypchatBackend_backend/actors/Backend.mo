import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";

import RegisterError "../types/RegisterError";
import ProfileUpdate "../types/ProfileUpdate";
import Profile "../types/Profile";
import UpdateProfileError "../types/UpdateProfileError";
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

actor Backend {

  var userToProfile : HashMap.HashMap<Principal, Profile.Profile> = HashMap.HashMap(0, Principal.equal, Principal.hash);
  var userToChats : HashMap.HashMap<Principal, Buffer.Buffer<Chat.Chat>> = HashMap.HashMap(0, Principal.equal, Principal.hash);

  public shared(msg) func registerHelper(thePrincipal : Principal, profileUpdate : ProfileUpdate.ProfileUpdate) : async Result.Result<(), RegisterError.RegisterError> {
    if (not ProfileUpdate.validate(profileUpdate)) {
      return #err(#InvalidProfile);
    };

    let value : ?Profile.Profile = userToProfile.get(thePrincipal);
    switch (value) {
      case (?value) {
        return #err(#AlreadyRegistered);
      };

      case null {
        let initialProfile : Profile.Profile = Profile.getDefault(thePrincipal);
        let profile : Profile.Profile = Profile.update(initialProfile, profileUpdate);
        userToProfile.put(thePrincipal, profile);
        userToChats.put(thePrincipal, Buffer.Buffer<Chat.Chat>(0));
      };
    };

    return #ok();
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

  public shared query(msg) func getMyProfile() : async Result.Result<Profile.Profile, GetMyProfileError.GetMyProfileError> {
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

  public shared query(msg) func getMyChatHeaders() : async Result.Result<[ChatHeader.ChatHeader], GetMyChatHeadersError.GetMyChatHeadersError> {
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

  public shared query(msg) func getMyChat(id : Nat8) : async Result.Result<SharedChat.SharedChat, GetMyChatError.GetMyChatError> {
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

  public shared(msg) func register(profileUpdate : ProfileUpdate.ProfileUpdate) : async Result.Result<(), RegisterError.RegisterError> {
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
        userToProfile.put(msg.caller, profile);
        userToChats.put(msg.caller, Buffer.Buffer<Chat.Chat>(0));
      };
    };

    return #ok();
  };

  public shared(msg) func updateProfile(profileUpdate : ProfileUpdate.ProfileUpdate) : async Result.Result<(), UpdateProfileError.UpdateProfileError> {
    let value : ?Profile.Profile = userToProfile.get(msg.caller);
    switch (value) {
      case null {
        return #err(#ProfileNotFound);
      };

      case (?value) {
        let profile : Profile.Profile = Profile.update(value, profileUpdate);
        userToProfile.put(msg.caller, profile);
        return #ok();
      };
    };

    return #ok();
  };

  public shared(msg) func createChat(otherUser : Principal) : async Result.Result<(), CreateChatError.CreateChatError> {
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
              func f(p : Principal) : Bool = Principal.equal(p, otherUser);
              if (Array.find(chat.users, f) != null) {
                return #err(#ChatAlreadyExists);
              };
            };
            for (chat in otherChats.vals()) {
              func f(p : Principal) : Bool = Principal.equal(p, msg.caller);
              if (Array.find(chat.users, f) != null) {
                return #err(#ChatAlreadyExists);
              };
            };

            let seed : Blob = await Random.blob();
            let chat : Chat.Chat = Chat.construct(seed, [msg.caller, otherUser]);

            myChats.add(chat);
            otherChats.add(chat);

            return #ok();
          };
        };
      };
    };
  };

  public shared(msg) func sendMessage(recipient : Principal, content : MessageContent.MessageContent) : async Result.Result<(), SendMessageError.SendMessageError> {
    let myChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(msg.caller);
    switch (myChats) {
      case null {
        return #err(#UserNotFound);
      };

      case (?myChats) {
        for (myCurrentChat in myChats.vals()) {
          func f(p : Principal) : Bool = Principal.equal(p, recipient);
          if (Array.find(myCurrentChat.users, f) != null) {
            let otherChats : ?Buffer.Buffer<Chat.Chat> = userToChats.get(recipient);
            switch (otherChats) {
              case null {
                return #err(#RecipientNotFound);
              };

              case (?otherChats) {
                for (otherCurrentChat in otherChats.vals()) {
                  func f(p : Principal) : Bool = Principal.equal(p, msg.caller);
                  if (Array.find(otherCurrentChat.users, f) != null) {
                    let message : Message.Message = Message.construct(msg.caller, content);

                    myCurrentChat.messages.add(message);

                    return #ok();
                  };
                };
              };
            };
          };
        };
        return #err(#RecipientNotFound);
      };
    };
  };
};