import { createRoot } from "react-dom/client";
import { StrictMode } from "react";
import { KcPage } from "./kc.gen";
import type { KcContext } from "./login/KcContext";
import "./styles.css";

const REGISTER_LOGIN_HINT_MARKER = "__hyops_register__";

function clearRegisterMarker(value: unknown) {
    return typeof value === "string" &&
        value.trim().toLowerCase() === REGISTER_LOGIN_HINT_MARKER
        ? ""
        : value;
}

function sanitizeKcContext(kcContext: KcContext): KcContext {
    const mutableContext = kcContext as unknown as {
        pageId?: string;
        username?: string;
        login?: { username?: string };
        auth?: { attemptedUsername?: string };
        register?: { formData?: { email?: string } };
        profile?: {
            formData?: { email?: string };
            attributesByName?: Record<
                string,
                {
                    value?: unknown;
                    values?: unknown[];
                }
            >;
        };
    };

    if (mutableContext.pageId === "login.ftl") {
        mutableContext.username = String(
            clearRegisterMarker(mutableContext.username) || ""
        );
        if (mutableContext.login) {
            mutableContext.login.username = String(
                clearRegisterMarker(mutableContext.login.username) || ""
            );
        }
        if (mutableContext.auth) {
            mutableContext.auth.attemptedUsername = String(
                clearRegisterMarker(mutableContext.auth.attemptedUsername) || ""
            );
        }
    }

    if (mutableContext.pageId === "register.ftl") {
        if (mutableContext.register?.formData) {
            mutableContext.register.formData.email = String(
                clearRegisterMarker(mutableContext.register.formData.email) || ""
            );
        }
        if (mutableContext.profile?.formData) {
            mutableContext.profile.formData.email = String(
                clearRegisterMarker(mutableContext.profile.formData.email) || ""
            );
        }
        const emailAttr = mutableContext.profile?.attributesByName?.email;
        if (emailAttr) {
            emailAttr.value = clearRegisterMarker(emailAttr.value);
            if (Array.isArray(emailAttr.values)) {
                emailAttr.values = emailAttr.values.map(clearRegisterMarker);
            }
        }
    }

    return kcContext;
}

function shouldRedirectToRegistration(kcContext: KcContext): string {
    const ctx = kcContext as unknown as {
        pageId?: string;
        username?: string;
        url?: { registrationUrl?: string };
    };

    if (ctx.pageId !== "login.ftl") {
        return "";
    }

    if (window.location.pathname.includes("/login-actions/registration")) {
        return "";
    }

    const search = new URLSearchParams(window.location.search);
    const prompt = String(search.get("prompt") || "").trim().toLowerCase();
    const intent = String(search.get("intent") || "").trim().toLowerCase();
    const loginHint = String(search.get("login_hint") || "").trim().toLowerCase();
    const contextUsername = String(ctx.username || "").trim().toLowerCase();
    const referrer = String(document.referrer || "").trim().toLowerCase();

    const shouldOpenRegister =
        prompt === "create" ||
        intent === "register" ||
        loginHint === REGISTER_LOGIN_HINT_MARKER ||
        contextUsername === REGISTER_LOGIN_HINT_MARKER ||
        referrer.includes("intent=register");

    if (!shouldOpenRegister) {
        return "";
    }

    return String(ctx.url?.registrationUrl || "").trim();
}

// The following block can be uncommented to test a specific page with `yarn dev`
// Don't forget to comment back or your bundle size will increase
/*
import { getKcContextMock } from "./login/KcPageStory";

if (import.meta.env.DEV) {
    window.kcContext = getKcContextMock({
        pageId: "register.ftl",
        overrides: {}
    });
}
*/

const kcContext = window.kcContext
    ? sanitizeKcContext(window.kcContext)
    : undefined;

const registrationUrl = kcContext ? shouldRedirectToRegistration(kcContext) : "";

if (registrationUrl) {
    window.location.replace(registrationUrl);
} else {
    createRoot(document.getElementById("root")!).render(
        <StrictMode>
            {!kcContext ? (
                <h1 className="hyops-dev-placeholder">No Keycloak Context</h1>
            ) : (
                <KcPage kcContext={kcContext} />
            )}
        </StrictMode>
    );
}
