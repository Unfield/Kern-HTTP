const std = @import("std");

pub const HttpStatus = enum(u16) {
    // 1xx - Informational
    Continue = 100,
    SwitchingProtocols = 101,
    EarlyHints = 103,

    // 2xx - Success
    OK = 200,
    Created = 201,
    Accepted = 202,
    NoContent = 204,

    // 3xx - Redirection
    MovedPermanently = 301,
    Found = 302,
    SeeOther = 303,
    NotModified = 304,
    TemporaryRedirect = 307,
    PermanentRedirect = 308,

    // 4xx - Client Error
    BadRequest = 400,
    Unauthorized = 401,
    Forbidden = 403,
    NotFound = 404,
    MethodNotAllowed = 405,
    Confilct = 409,
    Gone = 410,
    PayloadTooLarge = 413,
    UnsupportedMedia = 415,
    TooManyRequests = 429,

    // 5xx - Server Error
    InternalServerError = 500,
    NotImplemented = 501,
    BadGateway = 502,
    SeviceUnavailable = 503,
    GatewayTimeout = 504,

    pub fn reasonPhrase(self: HttpStatus) []const u8 {
        switch (self) {
            .Continue => return "Continue",
            .SwitchingProtocols => return "Switching Protocols",
            .EarlyHints => return "Early Hints",
            .OK => return "OK",
            .Created => return "Created",
            .Accepted => return "Accepted",
            .NoContent => return "No Content",
            .MovedPermanently => return "Moved Permanently",
            .Found => return "Found",
            .SeeOther => return "See Other",
            .NotModified => return "Not Modified",
            .TemporaryRedirect => return "Temporary Redirect",
            .PermanentRedirect => return "Permanent Redirect",
            .BadRequest => return "Bad Request",
            .Unauthorized => return "Unauthorized",
            .Forbidden => return "Forbidden",
            .NotFound => return "Not Found",
            .MethodNotAllowed => return "Method Not Allowed",
            .Confilct => return "Conflict",
            .Gone => return "Gone",
            .PayloadTooLarge => return "Payload Too Large",
            .UnsupportedMedia => return "Unsupported Media Type",
            .TooManyRequests => return "Too Many Requests",
            .InternalServerError => return "Internal Server Error",
            .NotImplemented => return "Not Implemented",
            .BadGateway => return "Bad Gateway",
            .SeviceUnavailable => return "Service Unavailable",
            .GatewayTimeout => return "Gateway Timeout",
        }
    }

    pub fn toInt(self: HttpStatus) u16 {
        return @intFromEnum(self);
    }
};

pub fn isError(status: HttpStatus) bool {
    return (status >= 400);
}

pub fn isRedirect(status: HttpStatus) bool {
    return (status >= 300 and status < 400);
}

pub fn isSuccess(status: HttpStatus) bool {
    return (status >= 200 and status < 300);
}
