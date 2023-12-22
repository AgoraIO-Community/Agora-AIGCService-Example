package io.agora.aigc_service_example;

import androidx.annotation.NonNull;

public class HistoryModel {
    private String date;
    private String sid;
    private String message;

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getSid() {
        return sid;
    }

    public void setSid(String sid) {
        this.sid = sid;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    @NonNull
    @Override
    public String toString() {
        return "HistoryModel{" +
                "date='" + date + '\'' +
                ", sid='" + sid + '\'' +
                ", message='" + message + '\'' +
                '}';
    }
}
