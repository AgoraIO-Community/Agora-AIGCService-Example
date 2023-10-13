package io.agora.ai_engine_example;

import android.content.Context;
import android.util.Log;

import io.agora.aigc.sdk.AIGCService;
import io.agora.aigc.sdk.AIGCServiceCallback;
import io.agora.aigc.sdk.AIGCServiceConfig;
import io.agora.aigc.sdk.constants.Language;
import io.agora.aigc.sdk.model.AIRole;
import io.agora.aigc.sdk.model.SceneMode;

public class AIGCServiceManager {
    private final static String TAG = "AIGCService-" + AIGCServiceManager.class.getSimpleName();
    private volatile static AIGCServiceManager mInstance = null;
    private AIGCService mAIGCService;

    private AIGCServiceManager() {

    }

    public static AIGCServiceManager getInstance() {
        if (mInstance == null) {
            synchronized (AIGCServiceManager.class) {
                if (mInstance == null) {
                    mInstance = new AIGCServiceManager();
                }
            }
        }
        return mInstance;
    }


    public void initAIGCService(AIGCServiceCallback serviceCallback, Context onContext) {
        Log.d(TAG, "initAIGCService");
        if (null == mAIGCService) {
            mAIGCService = AIGCService.create();
        }
        mAIGCService.initialize(new AIGCServiceConfig() {{
            this.context = onContext;
            this.callback = serviceCallback;
            this.enableLog = true;
            this.enableSaveLogToFile = true;
            this.userName = "AI";
            this.appId = KeyCenter.APP_ID;
            this.rtmToken = KeyCenter.getRtmToken(KeyCenter.getUserUid());
            this.userId = String.valueOf(KeyCenter.getUserUid());
            this.enableMultiTurnShortTermMemory = false;
            this.speechRecognitionFiltersLength = 0;
            this.input = new SceneMode() {{
                this.language = Language.ZH_CN;
                this.speechFrameSampleRates = 16000;
                this.speechFrameChannels = 1;
                this.speechFrameBits = 16;
            }};
            this.output = new SceneMode() {{
                this.language = Language.ZH_CN;
                this.speechFrameSampleRates = 16000;
                this.speechFrameChannels = 1;
                this.speechFrameBits = 16;
            }};
        }});
    }

    public AIGCService getAIGCService() {
        return mAIGCService;
    }


    public AIRole getCurrentAIRole() {
        if (null != mAIGCService) {
            return mAIGCService.getCurrentRole();
        }
        return null;
    }

    public void destroy() {
        AIGCService.destroy();
        mAIGCService = null;
    }
}
