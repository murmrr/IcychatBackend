import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Chat "Chat";
import Message "Message";

module {
  public type ChatHeader = {
    id : Nat;
    key : Text;
    otherUsers : [Principal];
    lastMessage : ?Message.Message;
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : ChatHeader {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    if (chat0.messages.size() > 0) {
      switch (chat0.keys.get(callerPrincipal)) {
        case null {
          return {
            id = chat0.id;
            key = "";
            otherUsers = Array.filter(chat0.users.toArray(), f);
            lastMessage = ?chat0.messages.get(chat0.messages.size() - 1);
          };
        };

        case (?value) {
          return {
            id = chat0.id;
            key = value;
            otherUsers = Array.filter(chat0.users.toArray(), f);
            lastMessage = ?chat0.messages.get(chat0.messages.size() - 1);
          };
        };
      };
    } else {
      switch (chat0.keys.get(callerPrincipal)) {
        case null {
          return {
            id = chat0.id;
            key = "";
            otherUsers = Array.filter(chat0.users.toArray(), f);
            lastMessage = null;
          };
        };

        case (?value) {
          return {
            id = chat0.id;
            key = value;
            otherUsers = Array.filter(chat0.users.toArray(), f);
            lastMessage = null;
          };
        };
      };
    };
  };  
};
