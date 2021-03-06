{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE OverloadedStrings #-}

module Html.Home where

import           Control.Monad.Except
import           Data.Text                   (Text)
import qualified Data.Text                   as T
import           Text.Blaze.Html5            as H
import           Text.Blaze.Html5.Attributes as A

import           Servant
import           Servant.HTML.Blaze

import           Types


type HomePage = Get '[HTML] Html
type BlogMain = Get '[HTML] Html
type AboutPage = Get '[HTML] Html

data PageType a = NoJS a
              | HighlightElm a

homePageHandlers :: SimpleHandler Html
homePageHandlers = pure $ homeSkeleton $ NoJS homeContent

blogMainHandlers :: SimpleHandler Html
blogMainHandlers = pure $ pageSkeleton $ HighlightElm elmApp

aboutPageHandlers :: SimpleHandler Html
aboutPageHandlers = pure $ docTypeHtml $ pageSkeleton $ NoJS aboutContent

homeContent :: H.Html
homeContent = consulting
  >> simplicity
    >> aboutUs
      >> ourServices
        >> getInTouch
          >> contactForm

homeSkeleton :: PageType H.Html -> H.Html
homeSkeleton pageType@(NoJS content) = docTypeHtml $ do
  pageHead pageType
  H.body $ H.div $ do
    H.div ! A.class_ "container" $ topNav
    content
    pageFooter

pageSkeleton :: PageType H.Html -> H.Html
pageSkeleton pageType@(NoJS content) = docTypeHtml $ do
  pageHead pageType
  H.body $
    H.div ! A.class_ "container" $ skeletonContent content
pageSkeleton pageType@(HighlightElm content) = docTypeHtml $ do
  pageHead pageType
  H.body $
    H.div ! A.class_ "container" $ skeletonContent content

skeletonContent :: H.Html -> H.Html
skeletonContent content = do
  topNav
  content
  pageFooter

pageHead :: PageType H.Html -> H.Html
pageHead pageType = H.head $ do
  H.title "Ekadanta.co / erik aker"
  H.meta ! A.name "viewport" ! A.content "width=device-width, initial-scale=1"
  H.link ! A.href "//cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.css" ! A.rel "stylesheet" ! A.type_ "text/css"
  H.link ! A.href "/assets/images/favicon.ico" ! A.rel "icon"
  H.link ! A.href "/assets/css/styles.min.css" ! A.rel "stylesheet" ! A.type_ "text/css"
  H.link ! A.href "https://fonts.googleapis.com/css?family=Roboto" ! A.rel "stylesheet"
  headScripts pageType

headScripts :: PageType H.Html -> H.Html
headScripts (NoJS _) = ""
headScripts (HighlightElm _) = do
  H.link ! A.href "/assets/highlight/styles/default.css" ! A.rel "stylesheet" ! A.type_ "text/css"
  H.script ! A.src "/assets/highlight/highlight.pack.js" $ ""
  H.script ! A.type_ "text/javascript" ! A.src "assets/js/elm.min.js" $ ""

topNav :: H.Html
topNav = H.section ! A.class_ "nav" $ do
    H.nav ! A.class_ "small-nav twelve columns" $
      H.ul ! A.class_ "small-nav" $ navLinkList
    H.nav ! A.class_ "navigation" $
      H.div ! A.class_ "row" $ do
        H.div ! A.class_ "three columns" $
          H.a ! A.class_ "button" ! href "/" $
            H.h5 "EKADANTA"
        H.div ! A.class_ "nine columns" $
          H.ul ! A.class_ "main-navigation u-pull-right" $ navLinkList

navLinkList :: H.Html
navLinkList = do
  H.li $ H.a ! href "/posts" $ "Blog"
  H.li $ H.a ! href "/projects" $ "Projects"
  H.li $ H.a ! href "/about" $ "About"
  H.li $ H.a ! href "/contact" $ "Contact"

pageFooter :: H.Html
pageFooter = H.footer ! A.id "page-footer" $
  H.div ! A.class_ "row" $ do
    H.p "Copyright (c) 2017 Erik Aker"
    H.script $ H.text ga

elmApp :: H.Html
elmApp = do
  H.div ! A.id "elm" ! A.class_ "main" $ ""
  H.script ! A.type_ "text/javascript" $
    "var node = document.getElementById('elm'); var app = Elm.Main.embed(node); hljs.initHighlightingOnLoad();"

consulting :: H.Html
consulting = H.section ! A.id "consulting" ! A.class_ "clients u-full-width" $
  H.div ! A.class_ "container" $
    H.div ! A.class_ "row" $ do
      H.h3 ! A.class_ "separator" $ "Consulting"
      H.h4 "Build and deploy new applications."
      H.h4 "Rework legacy software."
      H.h4 "Educate and inspire."

simplicity :: H.Html
simplicity = H.section ! A.id "simplify" ! A.class_ "simplify u-full-width featured-bg-image" $
  H.div ! A.class_ "container" $
    H.div ! A.class_ "row" $ do
      H.h3 ! A.class_ "separator white" $ "Modern web apps are a lot to manage"
      H.h4 "That's why we have one goal: simplicity."
      H.h4 "Whether we're maintaining or passing it on, we like to keep it simple."

aboutUs :: H.Html
aboutUs = H.section ! A.id "about" ! A.class_ "about u-full-width" $
  H.div ! A.class_ "container" $
    H.div ! A.class_ "row" $
      H.div ! A.class_ "twelve columns" $ do
        H.h3 ! A.class_ "separator" $ "About Us"
        H.h4 "Ekadanta Consulting is the work of Erik Aker."
        H.h4 $ H.text $ T.unlines ["Erik has expertise in Python, Javascript, web application development, "
                                , "database design, test practices, and cloud infrastructure and deployment."]

ourServices :: H.Html
ourServices = H.section ! A.id "creativity" ! A.class_ "creativity u-full-width featured-bg-image" $
  H.div ! A.class_ "container" $
    H.div ! A.class_ "row" $
      H.ul ! A.class_ "services" $ do
        serviceListItem "fa fa-space-shuttle" "Web Applications"
          "We specialize in building robust web applications using known and secure best practices."
        serviceListItem "fa fa-heartbeat" "DevOps/Architecture"
          "We'll deploy your application using cloud providers and get you prepared for your future growth."
        serviceListItem "fa fa-bath" "Testing/Transparency"
          "Everything we do comes with tests and documentation: we don't want to leave you hanging."

serviceListItem :: T.Text -> T.Text -> T.Text -> H.Html
serviceListItem icon title desc  = H.li ! A.class_"four columns" $ do
  H.div ! A.class_"service-image" $
    H.i ! A.class_ (toValue icon) $ ""
  H.h5 $ H.text title
  H.p $ H.text desc

getInTouch :: H.Html
getInTouch = H.section ! A.id "about" ! A.class_ "about u-full-width" $
  H.div ! A.class_ "container" $
    H.div ! A.class_ "row" $
      H.div ! A.class_ "twelve columns" $ do
        H.h3 ! A.class_ "separator" $ "Get In Touch"
        H.h4 $ H.text $ T.unlines ["To find out if we're available for your project, use the contact form "
                                  , "below. We may not be the right fit, but we'll be honest and upfront "
                                  , "if that's the case, so no worries."]

contactForm :: H.Html
contactForm = H.section ! A.id "contact" ! A.class_ "container contact-us u-full-width u-max-full-width" $
  H.div ! A.class_ "row" $ do
    H.div ! A.class_ "four columns contact-us-details" $ do
      H.h3 "Contact"
      H.h5 "ekadanta.co@gmail.com"
      H.br
      H.ul ! A.class_ "social-links" $ do
        H.li $
          H.a ! href "https://twitter.com/erewok" ! A.target "_new" $
            H.i ! A.class_ "fa fa-twitter" $ ""
        H.li $
          H.a ! href "https://github.com/erewok" ! A.target "_new" $
            H.i ! A.class_ "fa fa-github" $ ""
        H.li $
          H.a ! href "https://linkedin.com/in/erik-aker-41a3aa89" ! A.target "_new" $
            H.i ! A.class_ "fa fa-linkedin" $ ""
    H.div ! A.class_ "eight columns contact-us-form" $
      H.form ! A.method "post" ! A.action "/contact" $ do
        H.div ! A.class_ "row" $ do
          H.div ! A.class_ "six columns" $
            H.input ! A.class_ "u-full-width" ! A.type_ "text" ! A.name "cname" ! A.placeholder "Name" ! A.id "nameInput"
          H.div ! A.class_ "six columns" $
            H.input ! A.class_ "u-full-width" ! A.type_ "text" !  A.name "cemail" ! A.placeholder "Email" ! A.id "emailInput"
        H.textarea ! A.class_ "u-full-width" ! A.name "cmessage" ! A.placeholder "Message" ! A.id "messageInput" $ ""
        H.input ! A.class_ "button u-pull-right" ! A.type_ "submit" !  A.value "Send"

redirectPage :: String -> H.Html
redirectPage uri = pageSkeleton $ NoJS $ do
  H.head $ do
    H.title "redirecting..."
    H.meta ! A.httpEquiv "refresh" ! A.content (H.toValue $ "1; url=" ++ uri)
  H.body $ do
    H.p "You are being redirected."
    H.p $ do
      void "If your browser does not refresh the page click "
      H.a ! A.href (H.toValue uri) $ "here"


aboutContent :: H.Html
aboutContent = H.div ! A.class_ "row main" $
  H.div ! A.id "about-page" $
    H.div ! A.class_ "about-page-box" $ do
      H.div ! A.class_ "six columns left-about" $
        H.div ! A.class_ "about-page-photo" $
          H.div ! A.class_ "about-page-photo-overlay" $ ""
      H.div ! A.class_ "six columns right-about" $
        H.div ! A.class_ "about-page-content" $ do
          H.h4 "Erik Aker"
          H.p $ H.text aboutText1
          H.p "His interests include the following: "
          H.ul $ do
            H.li "Functional Programming"
            H.li "Natural Language Processing"
            H.li "Surfing"
            H.li "Playing with Milo"

aboutText1 :: Text
aboutText1 = T.unlines ["Formerly an English teacher and freelance writer, Erik Aker is a ",
                        "web application developer in San Diego."]


ga :: T.Text
ga = T.unlines ["(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){"
              , "(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),"
              , "m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)"
              , "})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');"
              , "ga('create', 'UA-89190801-1', 'auto');"
              , "ga('send', 'pageview');"]
