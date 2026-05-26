package com.learnflow.global.security;

public final class Permission {

    private Permission() {}

    public static final String COURSE_READ      = "course:read";
    public static final String COURSE_WRITE     = "course:write";
    public static final String COURSE_DELETE    = "course:delete";

    public static final String ENROLLMENT_READ  = "enrollment:read";
    public static final String ENROLLMENT_WRITE = "enrollment:write";

    public static final String PROGRESS_READ    = "progress:read";
    public static final String PROGRESS_WRITE   = "progress:write";

    public static final String USER_READ        = "user:read";
    public static final String USER_WRITE       = "user:write";

    public static final String REPORT_READ      = "report:read";
}
