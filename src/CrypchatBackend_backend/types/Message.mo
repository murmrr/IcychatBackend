import Time "mo:base/Time";

import MessageContent "MessageContent";

module {
  public type Message = {
    time : Time.Time;
    sender : Principal;
    content : MessageContent.MessageContent;
  };

  public func construct(sender0 : Principal, content0 : MessageContent.MessageContent) : Message {
      return {
          time = Time.now();
          sender = sender0;
          content = content0;
      };
  };
};
