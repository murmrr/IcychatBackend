import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Chat "Chat";
import Message "Message";

module {
  public type ChatHeader = {
    id : Nat;
    otherUsers : [Principal];
    lastMessage : ?Message.Message;
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : ChatHeader {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    if (chat0.messages.size() > 0) {
      return {
        id = chat0.id;
        otherUsers = Array.filter(chat0.users.toArray(), f);
        lastMessage = ?chat0.messages.get(chat0.messages.size() - 1);
      };
    } else {
      return {
        id = chat0.id;
        otherUsers = Array.filter(chat0.users.toArray(), f);
        lastMessage = null;
      };
    };
  };  
};
