import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Message "Message";
import Chat "Chat";

module {
  public type SharedChat = {
    otherUsers : [Principal];
    messages : [Message.Message];
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : SharedChat {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    return {
      otherUsers = Array.filter(chat0.users.toArray(), f);
      messages = chat0.messages.toArray();
    };
  };  
};
