import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Message "Message";
import Chat "Chat";
import StableBuffer "StableBuffer";

module {
  public type SharedChat = {
    otherUsers : [Principal];
    messages : [Message.Message];
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : SharedChat {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    return {
      otherUsers = Array.filter(StableBuffer.toArray(chat0.users), f);
      messages = StableBuffer.toArray(chat0.messages);
    };
  };
};
