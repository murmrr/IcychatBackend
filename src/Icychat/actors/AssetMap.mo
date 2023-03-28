import Result "mo:base/Result";

import Image "../types/Image";
import SetProfilePictureError "../types/SetProfilePictureError";

shared actor class AssetMap(userPrincipal : Principal) = this {
    var profilePicture : ?Image.Image = null;

    public shared query func getProfilePicture() : async ?Image.Image {
        return profilePicture;
    };

    public shared(msg) func setProfilePicture(img : Image.Image) : async Result.Result<(), SetProfilePictureError.SetProfilePictureError> {
        if (msg.caller != userPrincipal) {
            return #err(#NotAuthorized);
        };
        profilePicture := ?img;
        return #ok();
    };
};
