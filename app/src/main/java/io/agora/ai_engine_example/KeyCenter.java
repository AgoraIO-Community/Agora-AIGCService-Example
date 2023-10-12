package io.agora.ai_engine_example;

import java.util.Random;

import io.agora.media.RtcTokenBuilder;
import io.agora.rtm.RtmTokenBuilder;

public class KeyCenter {
    public static final int USER_MAX_UID = 10000;
    public static final String APP_ID = BuildConfig.APP_ID;

    private static int USER_RTC_UID = -1;


    public static int getUserUid() {
        if (-1 == USER_RTC_UID) {
            USER_RTC_UID = new Random().nextInt(USER_MAX_UID);
        }
        return USER_RTC_UID;
    }


    public static String getRtcToken(String channelId, int uid) {
        return new RtcTokenBuilder().buildTokenWithUid(
                APP_ID,
                BuildConfig.APP_CERTIFICATE,
                channelId,
                uid,
                RtcTokenBuilder.Role.Role_Publisher,
                0
        );
    }

    public static String getRtmToken(int uid) {
        try {
            return new RtmTokenBuilder().buildToken(
                    APP_ID,
                    BuildConfig.APP_CERTIFICATE,
                    String.valueOf(uid),
                    RtmTokenBuilder.Role.Rtm_User,
                    0
            );
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }

    }

}
