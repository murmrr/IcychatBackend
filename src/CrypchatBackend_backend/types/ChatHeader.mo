import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Chat "Chat";

module {
  public type ChatHeader = {
    id : Nat8;
    otherUsers : [Principal];
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : ChatHeader {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    return {
      id = chat0.id;
      otherUsers = Array.filter(chat0.users, f);
    };
  };  
};
