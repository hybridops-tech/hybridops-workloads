import { Suspense, lazy, useEffect, useLayoutEffect } from "react";
import type { ClassKey } from "keycloakify/login";
import type { KcContext } from "./KcContext";
import { useI18n } from "./i18n";
import DefaultPage from "keycloakify/login/DefaultPage";
import Template from "keycloakify/login/Template";
const UserProfileFormFields = lazy(
    () => import("keycloakify/login/UserProfileFormFields")
);

const doMakeUserConfirmPassword = true;
const REGISTER_LOGIN_HINT_MARKER = "__hyops_register__";

function clearMarkerValue(value: unknown) {
    return typeof value === "string" && value.trim().toLowerCase() === REGISTER_LOGIN_HINT_MARKER
        ? ""
        : value;
}

function sanitizeRegisterMarker(kcContext: KcContext) {
    const ctx = kcContext as unknown as {
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

    if (kcContext.pageId === "login.ftl") {
        if ("username" in ctx) {
            ctx.username = String(clearMarkerValue(ctx.username) || "");
        }

        if (ctx.login) {
            ctx.login.username = String(clearMarkerValue(ctx.login.username) || "");
        }

        if (ctx.auth) {
            ctx.auth.attemptedUsername = String(
                clearMarkerValue(ctx.auth.attemptedUsername) || ""
            );
        }
        return;
    }

    if (kcContext.pageId !== "register.ftl") {
        return;
    }

    if (ctx.register?.formData) {
        ctx.register.formData.email = String(clearMarkerValue(ctx.register.formData.email) || "");
    }

    if (ctx.profile?.formData) {
        ctx.profile.formData.email = String(clearMarkerValue(ctx.profile.formData.email) || "");
    }

    const emailAttr = ctx.profile?.attributesByName?.email;
    if (emailAttr) {
        emailAttr.value = clearMarkerValue(emailAttr.value);
        if (Array.isArray(emailAttr.values)) {
            emailAttr.values = emailAttr.values.map(clearMarkerValue);
        }
    }
}

function applySocialProviderLabels() {
    const socialProviders = document.querySelector<HTMLElement>("#kc-social-providers");
    if (!socialProviders) {
        return;
    }

    const links = socialProviders.querySelectorAll<HTMLAnchorElement>("a");

    for (const link of links) {
        const label = link.querySelector<HTMLElement>(".kc-social-provider-name, span");
        if (!label) {
            continue;
        }

        const providerName = String(
            label.dataset.hyopsProviderName || label.textContent || ""
        )
            .replace(/^Continue with\s+/i, "")
            .trim();

        if (!providerName) {
            continue;
        }

        label.dataset.hyopsProviderName = providerName;
        label.textContent = `Continue with ${providerName}`;
        link.setAttribute("aria-label", `Continue with ${providerName}`);
    }
}

function applyInlineInputPlaceholders() {
    const requiredFieldBanner = document.querySelector<HTMLElement>(
        ".kcLabelWrapperClass.subtitle"
    );
    if (requiredFieldBanner) {
        requiredFieldBanner.classList.add("hyops-hidden");
    }

    const groups = document.querySelectorAll<HTMLElement>(
        ".kcFormGroupClass, .form-group"
    );

    for (const group of groups) {
        const input = group.querySelector<HTMLInputElement | HTMLTextAreaElement>(
            ".kcInputClass, .pf-c-form-control, input[type='text'], input[type='email'], input[type='password'], input[type='search'], input[type='tel'], input[type='url'], textarea"
        );

        if (!input) {
            continue;
        }

        const type = input instanceof HTMLInputElement ? input.type : "";
        if (
            type === "hidden" ||
            type === "checkbox" ||
            type === "radio" ||
            type === "submit" ||
            type === "button"
        ) {
            continue;
        }

        const label = group.querySelector<HTMLLabelElement>("label.kcLabelClass, label");
        if (!label) {
            continue;
        }

        const rawLabelText = (label.textContent ?? "")
            .replace(/\s+/g, " ")
            .trim();

        const labelText = rawLabelText.replace(/\*/g, "").trim();

        if (!labelText) {
            continue;
        }

        const placeholderText = labelText;

        input.setAttribute("placeholder", placeholderText);

        input.setAttribute("aria-label", labelText);
        label.classList.add("hyops-sr-only");
        group.classList.add("hyops-inline-field");
    }
}

export default function KcPage(props: { kcContext: KcContext }) {
    const { kcContext } = props;
    sanitizeRegisterMarker(kcContext);

    const search = new URLSearchParams(window.location.search);
    const prompt = String(search.get("prompt") || "")
        .trim()
        .toLowerCase();
    const intent = String(search.get("intent") || "")
        .trim()
        .toLowerCase();
    const loginHint = String(search.get("login_hint") || "")
        .trim()
        .toLowerCase();
    const contextUsername = String(
        (kcContext as unknown as { username?: string }).username || ""
    )
        .trim()
        .toLowerCase();
    const referrer = String(document.referrer || "")
        .trim()
        .toLowerCase();
    const shouldOpenRegister =
        kcContext.pageId === "login.ftl" &&
        (prompt === "create" ||
            intent === "register" ||
            loginHint === REGISTER_LOGIN_HINT_MARKER ||
            contextUsername === REGISTER_LOGIN_HINT_MARKER ||
            referrer.includes("intent=register"));
    const registrationUrl = String(
        (kcContext as unknown as { url?: { registrationUrl?: string } }).url
            ?.registrationUrl || ""
    ).trim();

    if (
        shouldOpenRegister &&
        registrationUrl &&
        !window.location.pathname.includes("/login-actions/registration")
    ) {
        window.location.replace(registrationUrl);
        return null;
    }

    const { i18n } = useI18n({ kcContext });

    useLayoutEffect(() => {
        if (kcContext.pageId !== "login.ftl") {
            return;
        }

        if (!shouldOpenRegister) {
            return;
        }

        if (window.location.pathname.includes("/login-actions/registration")) {
            return;
        }

        if (!registrationUrl) {
            return;
        }

        window.location.replace(registrationUrl);
    }, [kcContext]);

    useEffect(() => {
        let isScheduled = false;

        const scheduleApply = () => {
            if (isScheduled) {
                return;
            }

            isScheduled = true;
            requestAnimationFrame(() => {
                isScheduled = false;
                applyInlineInputPlaceholders();
                applySocialProviderLabels();
            });
        };

        scheduleApply();

        const observer = new MutationObserver(() => {
            scheduleApply();
        });

        observer.observe(document.body, { childList: true, subtree: true });
        return () => {
            observer.disconnect();
        };
    }, [kcContext]);

    return (
        <Suspense>
            {(() => {
                switch (kcContext.pageId) {
                    default:
                        return (
                            <DefaultPage
                                kcContext={kcContext}
                                i18n={i18n}
                                classes={classes}
                                Template={Template}
                                doUseDefaultCss={false}
                                UserProfileFormFields={UserProfileFormFields}
                                doMakeUserConfirmPassword={doMakeUserConfirmPassword}
                            />
                        );
                }
            })()}
        </Suspense>
    );
}

const classes = {} satisfies { [key in ClassKey]?: string };
