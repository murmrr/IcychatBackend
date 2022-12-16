import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

import Chat "Chat";
import Message "Message";
import StableBuffer "StableBuffer";
import StableHashMap "FunctionalStableHashMap";

module {
  public type ChatHeader = {
    id : Nat;
    key : Text;
    otherUsers : [Principal];
    lastMessage : ?Message.Message;
  };

  public func construct(callerPrincipal : Principal, chat0 : Chat.Chat) : ChatHeader {
    func f(p : Principal) : Bool = not Principal.equal(p, callerPrincipal);
    if (StableBuffer.size(chat0.messages) > 0) {
      switch (StableHashMap.get(chat0.keys, Principal.equal, Principal.hash, callerPrincipal)) {
        case null {
          return {
            id = chat0.id;
            key = "";
            otherUsers = Array.filter(StableBuffer.toArray(chat0.users), f);
            lastMessage = ?StableBuffer.get(chat0.messages, StableBuffer.size(chat0.messages) - 1);
          };
        };

        case (?value) {
          return {
            id = chat0.id;
            key = value;
            otherUsers = Array.filter(StableBuffer.toArray(chat0.users), f);
            lastMessage = ?StableBuffer.get(chat0.messages, StableBuffer.size(chat0.messages) - 1);
          };
        };
      };
    } else {
      switch (StableHashMap.get(chat0.keys, Principal.equal, Principal.hash, callerPrincipal)) {
        case null {
          return {
            id = chat0.id;
            key = "";
            otherUsers = Array.filter(StableBuffer.toArray(chat0.users), f);
            lastMessage = null;
          };
        };

        case (?value) {
          return {
            id = chat0.id;
            key = value;
            otherUsers = Array.filter(StableBuffer.toArray(chat0.users), f);
            lastMessage = null;
          };
        };
      };
    };
  };
};
