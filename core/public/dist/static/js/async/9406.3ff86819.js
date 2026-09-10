"use strict";(self.webpackChunkfrontend=self.webpackChunkfrontend||[]).push([["9406"],{5562(e,o,t){t.d(o,{A:()=>l});var r=t(90290);function l(e,o){return(0,r.wB)(e,e=>{void 0!==e&&(o.value=e)}),(0,r.EW)(()=>void 0===e.value?o.value:e.value)}},4628(e,o,t){t.d(o,{Ay:()=>g,b8:()=>p});var r=t(90290),l=t(34828),i=t(49359),n=t(50922),a=t(4019),c=t(29794),d=t(86143),s=t(17436),v=t(62739),u=t(75454);let h=(0,u.cB)("layout",`
 color: var(--n-text-color);
 background-color: var(--n-color);
 box-sizing: border-box;
 position: relative;
 z-index: auto;
 flex: auto;
 overflow: hidden;
 transition:
 box-shadow .3s var(--n-bezier),
 background-color .3s var(--n-bezier),
 color .3s var(--n-bezier);
`,[(0,u.cB)("layout-scroll-container",`
 overflow-x: hidden;
 box-sizing: border-box;
 height: 100%;
 `),(0,u.cM)("absolute-positioned",`
 position: absolute;
 left: 0;
 right: 0;
 top: 0;
 bottom: 0;
 `)]),m={embedded:Boolean,position:v.Z,nativeScrollbar:{type:Boolean,default:!0},scrollbarProps:Object,onScroll:Function,contentClass:String,contentStyle:{type:[String,Object],default:""},hasSider:Boolean,siderPlacement:{type:String,default:"left"}},p=(0,c.D)("n-layout"),g=(0,r.pM)({name:"Layout",props:Object.assign(Object.assign({},i.A.props),m),setup(e){let o=(0,r.KR)(null),t=(0,r.KR)(null),{mergedClsPrefixRef:l,inlineThemeDisabled:c}=(0,n.Ay)(e),v=(0,i.A)("Layout","-layout",h,s.A,e,l);(0,r.Gt)(p,e);let u=0,m=0;(0,d.W)(()=>{if(e.nativeScrollbar){let e=o.value;e&&(e.scrollTop=m,e.scrollLeft=u)}});let g=(0,r.EW)(()=>{let{common:{cubicBezierEaseInOut:o},self:t}=v.value;return{"--n-bezier":o,"--n-color":e.embedded?t.colorEmbedded:t.color,"--n-text-color":t.textColor}}),b=c?(0,a.R)("layout",(0,r.EW)(()=>e.embedded?"e":""),g,e):void 0;return Object.assign({mergedClsPrefix:l,scrollableElRef:o,scrollbarInstRef:t,hasSiderStyle:{display:"flex",flexWrap:"nowrap",width:"100%",flexDirection:"row"},mergedTheme:v,handleNativeElScroll:o=>{var t;let r=o.target;u=r.scrollLeft,m=r.scrollTop,null==(t=e.onScroll)||t.call(e,o)},cssVars:c?void 0:g,themeClass:null==b?void 0:b.themeClass,onRender:null==b?void 0:b.onRender},{scrollTo:function(r,l){if(e.nativeScrollbar){let{value:e}=o;e&&(void 0===l?e.scrollTo(r):e.scrollTo(r,l))}else{let{value:e}=t;e&&e.scrollTo(r,l)}}})},render(){var e;let{mergedClsPrefix:o,hasSider:t}=this;null==(e=this.onRender)||e.call(this);let i=t?this.hasSiderStyle:void 0,n=[this.themeClass,!1,`${o}-layout`,`${o}-layout--${this.position}-positioned`];return(0,r.h)("div",{class:n,style:this.cssVars},this.nativeScrollbar?(0,r.h)("div",{ref:"scrollableElRef",class:[`${o}-layout-scroll-container`,this.contentClass],style:[this.contentStyle,i],onScroll:this.handleNativeElScroll},this.$slots):(0,r.h)(l.A,Object.assign({},this.scrollbarProps,{onScroll:this.onScroll,ref:"scrollbarInstRef",theme:this.mergedTheme.peers.Scrollbar,themeOverrides:this.mergedTheme.peerOverrides.Scrollbar,contentClass:this.contentClass,contentStyle:[this.contentStyle,i]}),this.$slots))}})},58588(e,o,t){t.d(o,{A:()=>u});var r=t(90290),l=t(49359),i=t(50922),n=t(4019),a=t(17436),c=t(62739),d=t(75454);let s=(0,d.cB)("layout-header",`
 transition:
 color .3s var(--n-bezier),
 background-color .3s var(--n-bezier),
 box-shadow .3s var(--n-bezier),
 border-color .3s var(--n-bezier);
 box-sizing: border-box;
 width: 100%;
 background-color: var(--n-color);
 color: var(--n-text-color);
`,[(0,d.cM)("absolute-positioned",`
 position: absolute;
 left: 0;
 right: 0;
 top: 0;
 `),(0,d.cM)("bordered",`
 border-bottom: solid 1px var(--n-border-color);
 `)]),v={position:c.Z,inverted:Boolean,bordered:{type:Boolean,default:!1}},u=(0,r.pM)({name:"LayoutHeader",props:Object.assign(Object.assign({},l.A.props),v),setup(e){let{mergedClsPrefixRef:o,inlineThemeDisabled:t}=(0,i.Ay)(e),c=(0,l.A)("Layout","-layout-header",s,a.A,e,o),d=(0,r.EW)(()=>{let{common:{cubicBezierEaseInOut:o},self:t}=c.value,r={"--n-bezier":o};return e.inverted?(r["--n-color"]=t.headerColorInverted,r["--n-text-color"]=t.textColorInverted,r["--n-border-color"]=t.headerBorderColorInverted):(r["--n-color"]=t.headerColor,r["--n-text-color"]=t.textColor,r["--n-border-color"]=t.headerBorderColor),r}),v=t?(0,n.R)("layout-header",(0,r.EW)(()=>e.inverted?"a":"b"),d,e):void 0;return{mergedClsPrefix:o,cssVars:t?void 0:d,themeClass:null==v?void 0:v.themeClass,onRender:null==v?void 0:v.onRender}},render(){var e;let{mergedClsPrefix:o}=this;return null==(e=this.onRender)||e.call(this),(0,r.h)("div",{class:[`${o}-layout-header`,this.themeClass,this.position&&`${o}-layout-header--${this.position}-positioned`,this.bordered&&`${o}-layout-header--bordered`],style:this.cssVars},this.$slots)}})},70559(e,o,t){t.d(o,{A:()=>z});var r=t(5562),l=t(90290),i=t(34828),n=t(49359),a=t(50922),c=t(4019),d=t(86275),s=t(16680),v=t(86143),u=t(17436),h=t(62739),m=t(4628),p=t(75454);let g=(0,p.cB)("layout-sider",`
 flex-shrink: 0;
 box-sizing: border-box;
 position: relative;
 z-index: 1;
 color: var(--n-text-color);
 transition:
 color .3s var(--n-bezier),
 border-color .3s var(--n-bezier),
 min-width .3s var(--n-bezier),
 max-width .3s var(--n-bezier),
 transform .3s var(--n-bezier),
 background-color .3s var(--n-bezier);
 background-color: var(--n-color);
 display: flex;
 justify-content: flex-end;
`,[(0,p.cM)("bordered",[(0,p.cE)("border",`
 content: "";
 position: absolute;
 top: 0;
 bottom: 0;
 width: 1px;
 background-color: var(--n-border-color);
 transition: background-color .3s var(--n-bezier);
 `)]),(0,p.cE)("left-placement",[(0,p.cM)("bordered",[(0,p.cE)("border",`
 right: 0;
 `)])]),(0,p.cM)("right-placement",`
 justify-content: flex-start;
 `,[(0,p.cM)("bordered",[(0,p.cE)("border",`
 left: 0;
 `)]),(0,p.cM)("collapsed",[(0,p.cB)("layout-toggle-button",[(0,p.cB)("base-icon",`
 transform: rotate(180deg);
 `)]),(0,p.cB)("layout-toggle-bar",[(0,p.c)("&:hover",[(0,p.cE)("top",{transform:"rotate(-12deg) scale(1.15) translateY(-2px)"}),(0,p.cE)("bottom",{transform:"rotate(12deg) scale(1.15) translateY(2px)"})])])]),(0,p.cB)("layout-toggle-button",`
 left: 0;
 transform: translateX(-50%) translateY(-50%);
 `,[(0,p.cB)("base-icon",`
 transform: rotate(0);
 `)]),(0,p.cB)("layout-toggle-bar",`
 left: -28px;
 transform: rotate(180deg);
 `,[(0,p.c)("&:hover",[(0,p.cE)("top",{transform:"rotate(12deg) scale(1.15) translateY(-2px)"}),(0,p.cE)("bottom",{transform:"rotate(-12deg) scale(1.15) translateY(2px)"})])])]),(0,p.cM)("collapsed",[(0,p.cB)("layout-toggle-bar",[(0,p.c)("&:hover",[(0,p.cE)("top",{transform:"rotate(-12deg) scale(1.15) translateY(-2px)"}),(0,p.cE)("bottom",{transform:"rotate(12deg) scale(1.15) translateY(2px)"})])]),(0,p.cB)("layout-toggle-button",[(0,p.cB)("base-icon",`
 transform: rotate(0);
 `)])]),(0,p.cB)("layout-toggle-button",`
 transition:
 color .3s var(--n-bezier),
 right .3s var(--n-bezier),
 left .3s var(--n-bezier),
 border-color .3s var(--n-bezier),
 background-color .3s var(--n-bezier);
 cursor: pointer;
 width: 24px;
 height: 24px;
 position: absolute;
 top: 50%;
 right: 0;
 border-radius: 50%;
 display: flex;
 align-items: center;
 justify-content: center;
 font-size: 18px;
 color: var(--n-toggle-button-icon-color);
 border: var(--n-toggle-button-border);
 background-color: var(--n-toggle-button-color);
 box-shadow: 0 2px 4px 0px rgba(0, 0, 0, .06);
 transform: translateX(50%) translateY(-50%);
 z-index: 1;
 `,[(0,p.cB)("base-icon",`
 transition: transform .3s var(--n-bezier);
 transform: rotate(180deg);
 `)]),(0,p.cB)("layout-toggle-bar",`
 cursor: pointer;
 height: 72px;
 width: 32px;
 position: absolute;
 top: calc(50% - 36px);
 right: -28px;
 `,[(0,p.cE)("top, bottom",`
 position: absolute;
 width: 4px;
 border-radius: 2px;
 height: 38px;
 left: 14px;
 transition: 
 background-color .3s var(--n-bezier),
 transform .3s var(--n-bezier);
 `),(0,p.cE)("bottom",`
 position: absolute;
 top: 34px;
 `),(0,p.c)("&:hover",[(0,p.cE)("top",{transform:"rotate(12deg) scale(1.15) translateY(-2px)"}),(0,p.cE)("bottom",{transform:"rotate(-12deg) scale(1.15) translateY(2px)"})]),(0,p.cE)("top, bottom",{backgroundColor:"var(--n-toggle-bar-color)"}),(0,p.c)("&:hover",[(0,p.cE)("top, bottom",{backgroundColor:"var(--n-toggle-bar-color-hover)"})])]),(0,p.cE)("border",`
 position: absolute;
 top: 0;
 right: 0;
 bottom: 0;
 width: 1px;
 transition: background-color .3s var(--n-bezier);
 `),(0,p.cB)("layout-sider-scroll-container",`
 flex-grow: 1;
 flex-shrink: 0;
 box-sizing: border-box;
 height: 100%;
 opacity: 0;
 transition: opacity .3s var(--n-bezier);
 max-width: 100%;
 `),(0,p.cM)("show-content",[(0,p.cB)("layout-sider-scroll-container",{opacity:1})]),(0,p.cM)("absolute-positioned",`
 position: absolute;
 left: 0;
 top: 0;
 bottom: 0;
 `)]),b=(0,l.pM)({props:{clsPrefix:{type:String,required:!0},onClick:Function},render(){let{clsPrefix:e}=this;return(0,l.h)("div",{onClick:this.onClick,class:`${e}-layout-toggle-bar`},(0,l.h)("div",{class:`${e}-layout-toggle-bar__top`}),(0,l.h)("div",{class:`${e}-layout-toggle-bar__bottom`}))}});var x=t(98250),f=t(71877);let C=(0,l.pM)({name:"LayoutToggleButton",props:{clsPrefix:{type:String,required:!0},onClick:Function},render(){let{clsPrefix:e}=this;return(0,l.h)("div",{class:`${e}-layout-toggle-button`,onClick:this.onClick},(0,l.h)(x.A,{clsPrefix:e},{default:()=>(0,l.h)(f.A,null)}))}}),y={position:h.Z,bordered:Boolean,collapsedWidth:{type:Number,default:48},width:{type:[Number,String],default:272},contentClass:String,contentStyle:{type:[String,Object],default:""},collapseMode:{type:String,default:"transform"},collapsed:{type:Boolean,default:void 0},defaultCollapsed:Boolean,showCollapsedContent:{type:Boolean,default:!0},showTrigger:{type:[Boolean,String],default:!1},nativeScrollbar:{type:Boolean,default:!0},inverted:Boolean,scrollbarProps:Object,triggerClass:String,triggerStyle:[String,Object],collapsedTriggerClass:String,collapsedTriggerStyle:[String,Object],"onUpdate:collapsed":[Function,Array],onUpdateCollapsed:[Function,Array],onAfterEnter:Function,onAfterLeave:Function,onExpand:[Function,Array],onCollapse:[Function,Array],onScroll:Function},z=(0,l.pM)({name:"LayoutSider",props:Object.assign(Object.assign({},n.A.props),y),setup(e){let o=(0,l.WQ)(m.b8),t=(0,l.KR)(null),i=(0,l.KR)(null),p=(0,l.KR)(e.defaultCollapsed),b=(0,r.A)((0,l.lW)(e,"collapsed"),p),x=(0,l.EW)(()=>(0,d.i)(b.value?e.collapsedWidth:e.width)),f=(0,l.EW)(()=>"transform"!==e.collapseMode?{}:{minWidth:(0,d.i)(e.width)}),C=(0,l.EW)(()=>o?o.siderPlacement:"left"),y=0,z=0;(0,v.W)(()=>{if(e.nativeScrollbar){let e=t.value;e&&(e.scrollTop=z,e.scrollLeft=y)}}),(0,l.Gt)(h.W,{collapsedRef:b,collapseModeRef:(0,l.lW)(e,"collapseMode")});let{mergedClsPrefixRef:w,inlineThemeDisabled:S}=(0,a.Ay)(e),A=(0,n.A)("Layout","-layout-sider",g,u.A,e,w),E=(0,l.EW)(()=>{let{common:{cubicBezierEaseInOut:o},self:t}=A.value,{siderToggleButtonColor:r,siderToggleButtonBorder:l,siderToggleBarColor:i,siderToggleBarColorHover:n}=t,a={"--n-bezier":o,"--n-toggle-button-color":r,"--n-toggle-button-border":l,"--n-toggle-bar-color":i,"--n-toggle-bar-color-hover":n};return e.inverted?(a["--n-color"]=t.siderColorInverted,a["--n-text-color"]=t.textColorInverted,a["--n-border-color"]=t.siderBorderColorInverted,a["--n-toggle-button-icon-color"]=t.siderToggleButtonIconColorInverted,a.__invertScrollbar=t.__invertScrollbar):(a["--n-color"]=t.siderColor,a["--n-text-color"]=t.textColor,a["--n-border-color"]=t.siderBorderColor,a["--n-toggle-button-icon-color"]=t.siderToggleButtonIconColor),a}),I=S?(0,c.R)("layout-sider",(0,l.EW)(()=>e.inverted?"a":"b"),E,e):void 0;return Object.assign({scrollableElRef:t,scrollbarInstRef:i,mergedClsPrefix:w,mergedTheme:A,styleMaxWidth:x,mergedCollapsed:b,scrollContainerStyle:f,siderPlacement:C,handleNativeElScroll:o=>{var t;let r=o.target;y=r.scrollLeft,z=r.scrollTop,null==(t=e.onScroll)||t.call(e,o)},handleTransitionend:function(o){var t,r;"max-width"===o.propertyName&&(b.value?null==(t=e.onAfterLeave)||t.call(e):null==(r=e.onAfterEnter)||r.call(e))},handleTriggerClick:function(){let{"onUpdate:collapsed":o,onUpdateCollapsed:t,onExpand:r,onCollapse:l}=e,{value:i}=b;t&&(0,s.T)(t,!i),o&&(0,s.T)(o,!i),p.value=!i,i?r&&(0,s.T)(r):l&&(0,s.T)(l)},inlineThemeDisabled:S,cssVars:E,themeClass:null==I?void 0:I.themeClass,onRender:null==I?void 0:I.onRender},{scrollTo:function(o,r){if(e.nativeScrollbar){let{value:e}=t;e&&(void 0===r?e.scrollTo(o):e.scrollTo(o,r))}else{let{value:e}=i;e&&e.scrollTo(o,r)}}})},render(){var e;let{mergedClsPrefix:o,mergedCollapsed:t,showTrigger:r}=this;return null==(e=this.onRender)||e.call(this),(0,l.h)("aside",{class:[`${o}-layout-sider`,this.themeClass,`${o}-layout-sider--${this.position}-positioned`,`${o}-layout-sider--${this.siderPlacement}-placement`,this.bordered&&`${o}-layout-sider--bordered`,t&&`${o}-layout-sider--collapsed`,(!t||this.showCollapsedContent)&&`${o}-layout-sider--show-content`],onTransitionend:this.handleTransitionend,style:[this.inlineThemeDisabled?void 0:this.cssVars,{maxWidth:this.styleMaxWidth,width:(0,d.i)(this.width)}]},this.nativeScrollbar?(0,l.h)("div",{class:[`${o}-layout-sider-scroll-container`,this.contentClass],onScroll:this.handleNativeElScroll,style:[this.scrollContainerStyle,{overflow:"auto"},this.contentStyle],ref:"scrollableElRef"},this.$slots):(0,l.h)(i.A,Object.assign({},this.scrollbarProps,{onScroll:this.onScroll,ref:"scrollbarInstRef",style:this.scrollContainerStyle,contentStyle:this.contentStyle,contentClass:this.contentClass,theme:this.mergedTheme.peers.Scrollbar,themeOverrides:this.mergedTheme.peerOverrides.Scrollbar,builtinThemeOverrides:this.inverted&&"true"===this.cssVars.__invertScrollbar?{colorHover:"rgba(255, 255, 255, .4)",color:"rgba(255, 255, 255, .3)"}:void 0}),this.$slots),r?"bar"===r?(0,l.h)(b,{clsPrefix:o,class:t?this.collapsedTriggerClass:this.triggerClass,style:t?this.collapsedTriggerStyle:this.triggerStyle,onClick:this.handleTriggerClick}):(0,l.h)(C,{clsPrefix:o,class:t?this.collapsedTriggerClass:this.triggerClass,style:t?this.collapsedTriggerStyle:this.triggerStyle,onClick:this.handleTriggerClick}):null,this.bordered?(0,l.h)("div",{class:`${o}-layout-sider__border`}):null)}})},62739(e,o,t){t.d(o,{W:()=>r,Z:()=>l});let r=(0,t(29794).D)("n-layout-sider"),l={type:String,default:"static"}},17436(e,o,t){t.d(o,{A:()=>a});var r=t(3755),l=t(90728),i=t(49359),n=t(28880);let a=(0,i.a)({name:"Layout",common:n.A,peers:{Scrollbar:l.A},self:function(e){let{baseColor:o,textColor2:t,bodyColor:l,cardColor:i,dividerColor:n,actionColor:a,scrollbarColor:c,scrollbarColorHover:d,invertedColor:s}=e;return{textColor:t,textColorInverted:"#FFF",color:l,colorEmbedded:a,headerColor:i,headerColorInverted:s,footerColor:a,footerColorInverted:s,headerBorderColor:n,headerBorderColorInverted:s,footerBorderColor:n,footerBorderColorInverted:s,siderBorderColor:n,siderBorderColorInverted:s,siderColor:i,siderColorInverted:s,siderToggleButtonBorder:`1px solid ${n}`,siderToggleButtonColor:o,siderToggleButtonIconColor:t,siderToggleButtonIconColorInverted:t,siderToggleBarColor:(0,r.sN)(l,c),siderToggleBarColorHover:(0,r.sN)(l,d),__invertScrollbar:"true"}}})},53696(e,o,t){t.d(o,{A:()=>Q});var r=t(29726),l=t(91929),i=t(5562),n=t(18872),a=t(90290),c=t(34006),d=t(88341),s=t(49359),v=t(50922),u=t(4019),h=t(16680),m=t(62739),p=t(6305),g=t(29794);let b=(0,g.D)("n-menu"),x=(0,g.D)("n-submenu"),f=(0,g.D)("n-menu-item-group");var C=t(48271),y=t(75454);let z=[(0,y.c)("&::before","background-color: var(--n-item-color-hover);"),(0,y.cE)("arrow",`
 color: var(--n-arrow-color-hover);
 `),(0,y.cE)("icon",`
 color: var(--n-item-icon-color-hover);
 `),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-hover);
 `,[(0,y.c)("a",`
 color: var(--n-item-text-color-hover);
 `),(0,y.cE)("extra",`
 color: var(--n-item-text-color-hover);
 `)])],w=[(0,y.cE)("icon",`
 color: var(--n-item-icon-color-hover-horizontal);
 `),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-hover-horizontal);
 `,[(0,y.c)("a",`
 color: var(--n-item-text-color-hover-horizontal);
 `),(0,y.cE)("extra",`
 color: var(--n-item-text-color-hover-horizontal);
 `)])],S=(0,y.c)([(0,y.cB)("menu",`
 background-color: var(--n-color);
 color: var(--n-item-text-color);
 overflow: hidden;
 transition: background-color .3s var(--n-bezier);
 box-sizing: border-box;
 font-size: var(--n-font-size);
 padding-bottom: 6px;
 `,[(0,y.cM)("horizontal",`
 max-width: 100%;
 width: 100%;
 display: flex;
 overflow: hidden;
 padding-bottom: 0;
 `,[(0,y.cB)("submenu","margin: 0;"),(0,y.cB)("menu-item","margin: 0;"),(0,y.cB)("menu-item-content",`
 padding: 0 20px;
 border-bottom: 2px solid #0000;
 `,[(0,y.c)("&::before","display: none;"),(0,y.cM)("selected","border-bottom: 2px solid var(--n-border-color-horizontal)")]),(0,y.cB)("menu-item-content",[(0,y.cM)("selected",[(0,y.cE)("icon","color: var(--n-item-icon-color-active-horizontal);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-active-horizontal);
 `,[(0,y.c)("a","color: var(--n-item-text-color-active-horizontal);"),(0,y.cE)("extra","color: var(--n-item-text-color-active-horizontal);")])]),(0,y.cM)("child-active",`
 border-bottom: 2px solid var(--n-border-color-horizontal);
 `,[(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-child-active-horizontal);
 `,[(0,y.c)("a",`
 color: var(--n-item-text-color-child-active-horizontal);
 `),(0,y.cE)("extra",`
 color: var(--n-item-text-color-child-active-horizontal);
 `)]),(0,y.cE)("icon",`
 color: var(--n-item-icon-color-child-active-horizontal);
 `)]),(0,y.C5)("disabled",[(0,y.C5)("selected, child-active",[(0,y.c)("&:focus-within",w)]),(0,y.cM)("selected",[A(null,[(0,y.cE)("icon","color: var(--n-item-icon-color-active-hover-horizontal);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-active-hover-horizontal);
 `,[(0,y.c)("a","color: var(--n-item-text-color-active-hover-horizontal);"),(0,y.cE)("extra","color: var(--n-item-text-color-active-hover-horizontal);")])])]),(0,y.cM)("child-active",[A(null,[(0,y.cE)("icon","color: var(--n-item-icon-color-child-active-hover-horizontal);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-child-active-hover-horizontal);
 `,[(0,y.c)("a","color: var(--n-item-text-color-child-active-hover-horizontal);"),(0,y.cE)("extra","color: var(--n-item-text-color-child-active-hover-horizontal);")])])]),A("border-bottom: 2px solid var(--n-border-color-horizontal);",w)]),(0,y.cB)("menu-item-content-header",[(0,y.c)("a","color: var(--n-item-text-color-horizontal);")])])]),(0,y.C5)("responsive",[(0,y.cB)("menu-item-content-header",`
 overflow: hidden;
 text-overflow: ellipsis;
 `)]),(0,y.cM)("collapsed",[(0,y.cB)("menu-item-content",[(0,y.cM)("selected",[(0,y.c)("&::before",`
 background-color: var(--n-item-color-active-collapsed) !important;
 `)]),(0,y.cB)("menu-item-content-header","opacity: 0;"),(0,y.cE)("arrow","opacity: 0;"),(0,y.cE)("icon","color: var(--n-item-icon-color-collapsed);")])]),(0,y.cB)("menu-item",`
 height: var(--n-item-height);
 margin-top: 6px;
 position: relative;
 `),(0,y.cB)("menu-item-content",`
 box-sizing: border-box;
 line-height: 1.75;
 height: 100%;
 display: grid;
 grid-template-areas: "icon content arrow";
 grid-template-columns: auto 1fr auto;
 align-items: center;
 cursor: pointer;
 position: relative;
 padding-right: 18px;
 transition:
 background-color .3s var(--n-bezier),
 padding-left .3s var(--n-bezier),
 border-color .3s var(--n-bezier);
 `,[(0,y.c)("> *","z-index: 1;"),(0,y.c)("&::before",`
 z-index: auto;
 content: "";
 background-color: #0000;
 position: absolute;
 left: 8px;
 right: 8px;
 top: 0;
 bottom: 0;
 pointer-events: none;
 border-radius: var(--n-border-radius);
 transition: background-color .3s var(--n-bezier);
 `),(0,y.cM)("disabled",`
 opacity: .45;
 cursor: not-allowed;
 `),(0,y.cM)("collapsed",[(0,y.cE)("arrow","transform: rotate(0);")]),(0,y.cM)("selected",[(0,y.c)("&::before","background-color: var(--n-item-color-active);"),(0,y.cE)("arrow","color: var(--n-arrow-color-active);"),(0,y.cE)("icon","color: var(--n-item-icon-color-active);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-active);
 `,[(0,y.c)("a","color: var(--n-item-text-color-active);"),(0,y.cE)("extra","color: var(--n-item-text-color-active);")])]),(0,y.cM)("child-active",[(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-child-active);
 `,[(0,y.c)("a",`
 color: var(--n-item-text-color-child-active);
 `),(0,y.cE)("extra",`
 color: var(--n-item-text-color-child-active);
 `)]),(0,y.cE)("arrow",`
 color: var(--n-arrow-color-child-active);
 `),(0,y.cE)("icon",`
 color: var(--n-item-icon-color-child-active);
 `)]),(0,y.C5)("disabled",[(0,y.C5)("selected, child-active",[(0,y.c)("&:focus-within",z)]),(0,y.cM)("selected",[A(null,[(0,y.cE)("arrow","color: var(--n-arrow-color-active-hover);"),(0,y.cE)("icon","color: var(--n-item-icon-color-active-hover);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-active-hover);
 `,[(0,y.c)("a","color: var(--n-item-text-color-active-hover);"),(0,y.cE)("extra","color: var(--n-item-text-color-active-hover);")])])]),(0,y.cM)("child-active",[A(null,[(0,y.cE)("arrow","color: var(--n-arrow-color-child-active-hover);"),(0,y.cE)("icon","color: var(--n-item-icon-color-child-active-hover);"),(0,y.cB)("menu-item-content-header",`
 color: var(--n-item-text-color-child-active-hover);
 `,[(0,y.c)("a","color: var(--n-item-text-color-child-active-hover);"),(0,y.cE)("extra","color: var(--n-item-text-color-child-active-hover);")])])]),(0,y.cM)("selected",[A(null,[(0,y.c)("&::before","background-color: var(--n-item-color-active-hover);")])]),A(null,z)]),(0,y.cE)("icon",`
 grid-area: icon;
 color: var(--n-item-icon-color);
 transition:
 color .3s var(--n-bezier),
 font-size .3s var(--n-bezier),
 margin-right .3s var(--n-bezier);
 box-sizing: content-box;
 display: inline-flex;
 align-items: center;
 justify-content: center;
 `),(0,y.cE)("arrow",`
 grid-area: arrow;
 font-size: 16px;
 color: var(--n-arrow-color);
 transform: rotate(180deg);
 opacity: 1;
 transition:
 color .3s var(--n-bezier),
 transform 0.2s var(--n-bezier),
 opacity 0.2s var(--n-bezier);
 `),(0,y.cB)("menu-item-content-header",`
 grid-area: content;
 transition:
 color .3s var(--n-bezier),
 opacity .3s var(--n-bezier);
 opacity: 1;
 white-space: nowrap;
 color: var(--n-item-text-color);
 `,[(0,y.c)("a",`
 outline: none;
 text-decoration: none;
 transition: color .3s var(--n-bezier);
 color: var(--n-item-text-color);
 `,[(0,y.c)("&::before",`
 content: "";
 position: absolute;
 left: 0;
 right: 0;
 top: 0;
 bottom: 0;
 `)]),(0,y.cE)("extra",`
 font-size: .93em;
 color: var(--n-group-text-color);
 transition: color .3s var(--n-bezier);
 `)])]),(0,y.cB)("submenu",`
 cursor: pointer;
 position: relative;
 margin-top: 6px;
 `,[(0,y.cB)("menu-item-content",`
 height: var(--n-item-height);
 `),(0,y.cB)("submenu-children",`
 overflow: hidden;
 padding: 0;
 `,[(0,C._)({duration:".2s"})])]),(0,y.cB)("menu-item-group",[(0,y.cB)("menu-item-group-title",`
 margin-top: 6px;
 color: var(--n-group-text-color);
 cursor: default;
 font-size: .93em;
 height: 36px;
 display: flex;
 align-items: center;
 transition:
 padding-left .3s var(--n-bezier),
 color .3s var(--n-bezier);
 `)])]),(0,y.cB)("menu-tooltip",[(0,y.c)("a",`
 color: inherit;
 text-decoration: none;
 `)]),(0,y.cB)("menu-divider",`
 transition: background-color .3s var(--n-bezier);
 background-color: var(--n-divider-color);
 height: 1px;
 margin: 6px 18px;
 `)]);function A(e,o){return[(0,y.cM)("hover",e,o),(0,y.c)("&:hover",e,o)]}var E=t(29440),I=t(54254),B=t(14063),T=t(80785),N=t(98250);let R=(0,a.pM)({name:"ChevronDownFilled",render:()=>(0,a.h)("svg",{viewBox:"0 0 16 16",fill:"none",xmlns:"http://www.w3.org/2000/svg"},(0,a.h)("path",{d:"M3.20041 5.73966C3.48226 5.43613 3.95681 5.41856 4.26034 5.70041L8 9.22652L11.7397 5.70041C12.0432 5.41856 12.5177 5.43613 12.7996 5.73966C13.0815 6.0432 13.0639 6.51775 12.7603 6.7996L8.51034 10.7996C8.22258 11.0668 7.77743 11.0668 7.48967 10.7996L3.23966 6.7996C2.93613 6.51775 2.91856 6.0432 3.20041 5.73966Z",fill:"currentColor"}))});var k=t(4744);let H=(0,a.pM)({name:"MenuOptionContent",props:{collapsed:Boolean,disabled:Boolean,title:[String,Function],icon:Function,extra:[String,Function],showArrow:Boolean,childActive:Boolean,hover:Boolean,paddingLeft:Number,selected:Boolean,maxIconSize:{type:Number,required:!0},activeIconSize:{type:Number,required:!0},iconMarginRight:{type:Number,required:!0},clsPrefix:{type:String,required:!0},onClick:Function,tmNode:{type:Object,required:!0},isEllipsisPlaceholder:Boolean},setup(e){let{props:o}=(0,a.WQ)(b);return{menuProps:o,style:(0,a.EW)(()=>{let{paddingLeft:o}=e;return{paddingLeft:o&&`${o}px`}}),iconStyle:(0,a.EW)(()=>{let{maxIconSize:o,activeIconSize:t,iconMarginRight:r}=e;return{width:`${o}px`,height:`${o}px`,fontSize:`${t}px`,marginRight:`${r}px`}})}},render(){let{clsPrefix:e,tmNode:o,menuProps:{renderIcon:t,renderLabel:r,renderExtra:l,expandIcon:i}}=this,n=t?t(o.rawNode):(0,k.X)(this.icon);return(0,a.h)("div",{onClick:e=>{var o;null==(o=this.onClick)||o.call(this,e)},role:"none",class:[`${e}-menu-item-content`,{[`${e}-menu-item-content--selected`]:this.selected,[`${e}-menu-item-content--collapsed`]:this.collapsed,[`${e}-menu-item-content--child-active`]:this.childActive,[`${e}-menu-item-content--disabled`]:this.disabled,[`${e}-menu-item-content--hover`]:this.hover}],style:this.style},n&&(0,a.h)("div",{class:`${e}-menu-item-content__icon`,style:this.iconStyle,role:"none"},[n]),(0,a.h)("div",{class:`${e}-menu-item-content-header`,role:"none"},this.isEllipsisPlaceholder?this.title:r?r(o.rawNode):(0,k.X)(this.title),this.extra||l?(0,a.h)("span",{class:`${e}-menu-item-content-header__extra`}," ",l?l(o.rawNode):(0,k.X)(this.extra)):null),this.showArrow?(0,a.h)(N.A,{ariaHidden:!0,class:`${e}-menu-item-content__arrow`,clsPrefix:e},{default:()=>i?i(o.rawNode):(0,a.h)(R,null)}):null)}});function P(e){let o=(0,a.WQ)(b),{props:t,mergedCollapsedRef:r}=o,l=(0,a.WQ)(x,null),i=(0,a.WQ)(f,null),n=(0,a.EW)(()=>"horizontal"===t.mode),c=(0,a.EW)(()=>n.value?t.dropdownPlacement:"tmNodes"in e?"right-start":"right"),d=(0,a.EW)(()=>{var e;return Math.max(null!=(e=t.collapsedIconSize)?e:t.iconSize,t.iconSize)}),s=(0,a.EW)(()=>{var o;return!n.value&&e.root&&r.value&&null!=(o=t.collapsedIconSize)?o:t.iconSize}),v=(0,a.EW)(()=>{if(n.value)return;let{collapsedWidth:o,indent:a,rootIndent:c}=t,{root:s,isGroup:v}=e;return s?r.value?o/2-d.value/2:void 0===c?a:c:i&&"number"==typeof i.paddingLeftRef.value?a/2+i.paddingLeftRef.value:l&&"number"==typeof l.paddingLeftRef.value?(v?a/2:a)+l.paddingLeftRef.value:0}),u=(0,a.EW)(()=>{let{collapsedWidth:o,indent:l,rootIndent:i}=t,{value:a}=d,{root:c}=e;return!n.value&&c&&r.value?(void 0===i?l:i)+a+8-(o+a)/2:8});return{dropdownPlacement:c,activeIconSize:s,maxIconSize:d,paddingLeft:v,iconMarginRight:u,NMenu:o,NSubmenu:l,NMenuOptionGroup:i}}let M={internalKey:{type:[String,Number],required:!0},root:Boolean,isGroup:Boolean,level:{type:Number,required:!0},title:[String,Function],extra:[String,Function]};var W=t(33199);let $=(0,a.pM)({name:"MenuDivider",setup(){let{mergedClsPrefixRef:e,isHorizontalRef:o}=(0,a.WQ)(b);return()=>o.value?null:(0,a.h)("div",{class:`${e.value}-menu-divider`})}});var O=t(48920);let F=Object.assign(Object.assign({},M),{tmNode:{type:Object,required:!0},disabled:Boolean,icon:Function,onClick:Function}),L=(0,B.Y)(F),j=(0,a.pM)({name:"MenuOption",props:F,setup(e){let o=P(e),{NSubmenu:t,NMenu:r,NMenuOptionGroup:l}=o,{props:i,mergedClsPrefixRef:n,mergedCollapsedRef:c}=r,d=t?t.mergedDisabledRef:l?l.mergedDisabledRef:{value:!1},s=(0,a.EW)(()=>d.value||e.disabled);return{mergedClsPrefix:n,dropdownPlacement:o.dropdownPlacement,paddingLeft:o.paddingLeft,iconMarginRight:o.iconMarginRight,maxIconSize:o.maxIconSize,activeIconSize:o.activeIconSize,mergedTheme:r.mergedThemeRef,menuProps:i,dropdownEnabled:(0,E.A)(()=>e.root&&c.value&&"horizontal"!==i.mode&&!s.value),selected:(0,E.A)(()=>r.mergedValueRef.value===e.internalKey),mergedDisabled:s,handleClick:function(o){s.value||(r.doSelect(e.internalKey,e.tmNode.rawNode),function(o){let{onClick:t}=e;t&&t(o)}(o))}}},render(){let{mergedClsPrefix:e,mergedTheme:o,tmNode:t,menuProps:{renderLabel:r,nodeProps:l}}=this,i=null==l?void 0:l(t.rawNode);return(0,a.h)("div",Object.assign({},i,{role:"menuitem",class:[`${e}-menu-item`,null==i?void 0:i.class]}),(0,a.h)(O.A,{theme:o.peers.Tooltip,themeOverrides:o.peerOverrides.Tooltip,trigger:"hover",placement:this.dropdownPlacement,disabled:!this.dropdownEnabled||void 0===this.title,internalExtraClass:["menu-tooltip"]},{default:()=>r?r(t.rawNode):(0,k.X)(this.title),trigger:()=>(0,a.h)(H,{tmNode:t,clsPrefix:e,paddingLeft:this.paddingLeft,iconMarginRight:this.iconMarginRight,maxIconSize:this.maxIconSize,activeIconSize:this.activeIconSize,selected:this.selected,title:this.title,extra:this.extra,disabled:this.mergedDisabled,icon:this.icon,onClick:this.handleClick})}))}}),_=Object.assign(Object.assign({},M),{tmNode:{type:Object,required:!0},tmNodes:{type:Array,required:!0}}),K=(0,B.Y)(_),D=(0,a.pM)({name:"MenuOptionGroup",props:_,setup(e){let o=P(e),{NSubmenu:t}=o,r=(0,a.EW)(()=>null!=t&&!!t.mergedDisabledRef.value||e.tmNode.disabled);(0,a.Gt)(f,{paddingLeftRef:o.paddingLeft,mergedDisabledRef:r});let{mergedClsPrefixRef:l,props:i}=(0,a.WQ)(b);return function(){let{value:t}=l,r=o.paddingLeft.value,{nodeProps:n}=i,c=null==n?void 0:n(e.tmNode.rawNode);return(0,a.h)("div",{class:`${t}-menu-item-group`,role:"group"},(0,a.h)("div",Object.assign({},c,{class:[`${t}-menu-item-group-title`,null==c?void 0:c.class],style:[(null==c?void 0:c.style)||"",void 0!==r?`padding-left: ${r}px;`:""]}),(0,k.X)(e.title),e.extra?(0,a.h)(a.FK,null," ",(0,k.X)(e.extra)):null),(0,a.h)("div",null,e.tmNodes.map(e=>G(e,i))))}}});function V(e){return"divider"===e.type||"render"===e.type}function G(e,o){let{rawNode:t}=e,{show:r}=t;if(!1===r)return null;if(V(t))return"divider"===t.type?(0,a.h)($,Object.assign({key:e.key},t.props)):null;let{labelField:l}=o,{key:i,level:n,isGroup:c}=e,d=Object.assign(Object.assign({},t),{title:t.title||t[l],extra:t.titleExtra||t.extra,key:i,internalKey:i,level:n,root:0===n,isGroup:c});return e.children?e.isGroup?(0,a.h)(D,(0,W.a)(d,K,{tmNode:e,tmNodes:e.children,key:i})):(0,a.h)(Y,(0,W.a)(d,q,{key:i,rawNodes:t[o.childrenField],tmNodes:e.children,tmNode:e})):(0,a.h)(j,(0,W.a)(d,L,{key:i,tmNode:e}))}let U=Object.assign(Object.assign({},M),{rawNodes:{type:Array,default:()=>[]},tmNodes:{type:Array,default:()=>[]},tmNode:{type:Object,required:!0},disabled:Boolean,icon:Function,onClick:Function,domId:String,virtualChildActive:{type:Boolean,default:void 0},isEllipsisPlaceholder:Boolean}),q=(0,B.Y)(U),Y=(0,a.pM)({name:"Submenu",props:U,setup(e){let o=P(e),{NMenu:t,NSubmenu:r}=o,{props:l,mergedCollapsedRef:i,mergedThemeRef:n}=t,c=(0,a.EW)(()=>{let{disabled:o}=e;return null!=r&&!!r.mergedDisabledRef.value||!!l.disabled||o}),d=(0,a.KR)(!1);return(0,a.Gt)(x,{paddingLeftRef:o.paddingLeft,mergedDisabledRef:c}),(0,a.Gt)(f,null),{menuProps:l,mergedTheme:n,doSelect:t.doSelect,inverted:t.invertedRef,isHorizontal:t.isHorizontalRef,mergedClsPrefix:t.mergedClsPrefixRef,maxIconSize:o.maxIconSize,activeIconSize:o.activeIconSize,iconMarginRight:o.iconMarginRight,dropdownPlacement:o.dropdownPlacement,dropdownShow:d,paddingLeft:o.paddingLeft,mergedDisabled:c,mergedValue:t.mergedValueRef,childActive:(0,E.A)(()=>{var o;return null!=(o=e.virtualChildActive)?o:t.activePathRef.value.includes(e.internalKey)}),collapsed:(0,a.EW)(()=>"horizontal"!==l.mode&&(!!i.value||!t.mergedExpandedKeysRef.value.includes(e.internalKey))),dropdownEnabled:(0,a.EW)(()=>!c.value&&("horizontal"===l.mode||i.value)),handlePopoverShowChange:function(e){d.value=e},handleClick:function(){c.value||(i.value||t.toggleExpand(e.internalKey),function(){let{onClick:o}=e;o&&o()}())}}},render(){var e;let{mergedClsPrefix:o,menuProps:{renderIcon:t,renderLabel:r}}=this,l=()=>{let{isHorizontal:e,paddingLeft:o,collapsed:t,mergedDisabled:r,maxIconSize:l,activeIconSize:i,title:n,childActive:c,icon:d,handleClick:s,menuProps:{nodeProps:v},dropdownShow:u,iconMarginRight:h,tmNode:m,mergedClsPrefix:p,isEllipsisPlaceholder:g,extra:b}=this,x=null==v?void 0:v(m.rawNode);return(0,a.h)("div",Object.assign({},x,{class:[`${p}-menu-item`,null==x?void 0:x.class],role:"menuitem"}),(0,a.h)(H,{tmNode:m,paddingLeft:o,collapsed:t,disabled:r,iconMarginRight:h,maxIconSize:l,activeIconSize:i,title:n,extra:b,showArrow:!e,childActive:c,clsPrefix:p,icon:d,hover:u,onClick:s,isEllipsisPlaceholder:g}))},i=()=>(0,a.h)(I.A,null,{default:()=>{let{tmNodes:e,collapsed:t}=this;return t?null:(0,a.h)("div",{class:`${o}-submenu-children`,role:"menu"},e.map(e=>G(e,this.menuProps)))}});return this.root?(0,a.h)(T.A,Object.assign({size:"large",trigger:"hover"},null==(e=this.menuProps)?void 0:e.dropdownProps,{themeOverrides:this.mergedTheme.peerOverrides.Dropdown,theme:this.mergedTheme.peers.Dropdown,builtinThemeOverrides:{fontSizeLarge:"14px",optionIconSizeLarge:"18px"},value:this.mergedValue,disabled:!this.dropdownEnabled,placement:this.dropdownPlacement,keyField:this.menuProps.keyField,labelField:this.menuProps.labelField,childrenField:this.menuProps.childrenField,onUpdateShow:this.handlePopoverShowChange,options:this.rawNodes,onSelect:this.doSelect,inverted:this.inverted,renderIcon:t,renderLabel:r}),{default:()=>(0,a.h)("div",{class:`${o}-submenu`,role:"menu","aria-expanded":!this.collapsed,id:this.domId},l(),this.isHorizontal?null:i())}):(0,a.h)("div",{class:`${o}-submenu`,role:"menu","aria-expanded":!this.collapsed,id:this.domId},l(),i())}}),X=Object.assign(Object.assign({},s.A.props),{options:{type:Array,default:()=>[]},collapsed:{type:Boolean,default:void 0},collapsedWidth:{type:Number,default:48},iconSize:{type:Number,default:20},collapsedIconSize:{type:Number,default:24},rootIndent:Number,indent:{type:Number,default:32},labelField:{type:String,default:"label"},keyField:{type:String,default:"key"},childrenField:{type:String,default:"children"},disabledField:{type:String,default:"disabled"},defaultExpandAll:Boolean,defaultExpandedKeys:Array,expandedKeys:Array,value:[String,Number],defaultValue:{type:[String,Number],default:null},mode:{type:String,default:"vertical"},watchProps:{type:Array,default:void 0},disabled:Boolean,show:{type:Boolean,default:!0},inverted:Boolean,"onUpdate:expandedKeys":[Function,Array],onUpdateExpandedKeys:[Function,Array],onUpdateValue:[Function,Array],"onUpdate:value":[Function,Array],expandIcon:Function,renderIcon:Function,renderLabel:Function,renderExtra:Function,dropdownProps:Object,accordion:Boolean,nodeProps:Function,dropdownPlacement:{type:String,default:"bottom"},responsive:Boolean,items:Array,onOpenNamesChange:[Function,Array],onSelect:[Function,Array],onExpandedNamesChange:[Function,Array],expandedNames:Array,defaultExpandedNames:Array}),Q=(0,a.pM)({name:"Menu",inheritAttrs:!1,props:X,setup(e){let{mergedClsPrefixRef:o,inlineThemeDisabled:t}=(0,v.Ay)(e),c=(0,s.A)("Menu","-menu",S,p.Ay,e,o),d=(0,a.WQ)(m.W,null),g=(0,a.EW)(()=>{var o;let{collapsed:t}=e;if(void 0!==t)return t;if(d){let{collapseModeRef:e,collapsedRef:t}=d;if("width"===e.value)return null!=(o=t.value)&&o}return!1}),x=(0,a.EW)(()=>{let{keyField:o,childrenField:t,disabledField:r}=e;return(0,l.G)(e.items||e.options,{getIgnored:e=>V(e),getChildren:e=>e[t],getDisabled:e=>e[r],getKey(e){var t;return null!=(t=e[o])?t:e.name}})}),f=(0,a.EW)(()=>new Set(x.value.treeNodes.map(e=>e.key))),{watchProps:C}=e,y=(0,a.KR)(null);(null==C?void 0:C.includes("defaultValue"))?(0,a.nT)(()=>{y.value=e.defaultValue}):y.value=e.defaultValue;let z=(0,a.lW)(e,"value"),w=(0,i.A)(z,y),A=(0,a.KR)([]),E=()=>{A.value=e.defaultExpandAll?x.value.getNonLeafKeys():e.defaultExpandedNames||e.defaultExpandedKeys||x.value.getPath(w.value,{includeSelf:!1}).keyPath};(null==C?void 0:C.includes("defaultExpandedKeys"))?(0,a.nT)(E):E();let I=(0,n.A)(e,["expandedNames","expandedKeys"]),B=(0,i.A)(I,A),T=(0,a.EW)(()=>x.value.treeNodes),N=(0,a.EW)(()=>x.value.getPath(w.value).keyPath);function R(o){let{"onUpdate:expandedKeys":t,onUpdateExpandedKeys:r,onExpandedNamesChange:l,onOpenNamesChange:i}=e;t&&(0,h.T)(t,o),r&&(0,h.T)(r,o),l&&(0,h.T)(l,o),i&&(0,h.T)(i,o),A.value=o}(0,a.Gt)(b,{props:e,mergedCollapsedRef:g,mergedThemeRef:c,mergedValueRef:w,mergedExpandedKeysRef:B,activePathRef:N,mergedClsPrefixRef:o,isHorizontalRef:(0,a.EW)(()=>"horizontal"===e.mode),invertedRef:(0,a.lW)(e,"inverted"),doSelect:function(o,t){let{"onUpdate:value":r,onUpdateValue:l,onSelect:i}=e;l&&(0,h.T)(l,o,t),r&&(0,h.T)(r,o,t),i&&(0,h.T)(i,o,t),y.value=o},toggleExpand:function(o){let t=Array.from(B.value),r=t.findIndex(e=>e===o);if(~r)t.splice(r,1);else{if(e.accordion&&f.value.has(o)){let e=t.findIndex(e=>f.value.has(e));e>-1&&t.splice(e,1)}t.push(o)}R(t)}});let k=(0,a.EW)(()=>{let{inverted:o}=e,{common:{cubicBezierEaseInOut:t},self:r}=c.value,{borderRadius:l,borderColorHorizontal:i,fontSize:n,itemHeight:a,dividerColor:d}=r,s={"--n-divider-color":d,"--n-bezier":t,"--n-font-size":n,"--n-border-color-horizontal":i,"--n-border-radius":l,"--n-item-height":a};return o?(s["--n-group-text-color"]=r.groupTextColorInverted,s["--n-color"]=r.colorInverted,s["--n-item-text-color"]=r.itemTextColorInverted,s["--n-item-text-color-hover"]=r.itemTextColorHoverInverted,s["--n-item-text-color-active"]=r.itemTextColorActiveInverted,s["--n-item-text-color-child-active"]=r.itemTextColorChildActiveInverted,s["--n-item-text-color-child-active-hover"]=r.itemTextColorChildActiveInverted,s["--n-item-text-color-active-hover"]=r.itemTextColorActiveHoverInverted,s["--n-item-icon-color"]=r.itemIconColorInverted,s["--n-item-icon-color-hover"]=r.itemIconColorHoverInverted,s["--n-item-icon-color-active"]=r.itemIconColorActiveInverted,s["--n-item-icon-color-active-hover"]=r.itemIconColorActiveHoverInverted,s["--n-item-icon-color-child-active"]=r.itemIconColorChildActiveInverted,s["--n-item-icon-color-child-active-hover"]=r.itemIconColorChildActiveHoverInverted,s["--n-item-icon-color-collapsed"]=r.itemIconColorCollapsedInverted,s["--n-item-text-color-horizontal"]=r.itemTextColorHorizontalInverted,s["--n-item-text-color-hover-horizontal"]=r.itemTextColorHoverHorizontalInverted,s["--n-item-text-color-active-horizontal"]=r.itemTextColorActiveHorizontalInverted,s["--n-item-text-color-child-active-horizontal"]=r.itemTextColorChildActiveHorizontalInverted,s["--n-item-text-color-child-active-hover-horizontal"]=r.itemTextColorChildActiveHoverHorizontalInverted,s["--n-item-text-color-active-hover-horizontal"]=r.itemTextColorActiveHoverHorizontalInverted,s["--n-item-icon-color-horizontal"]=r.itemIconColorHorizontalInverted,s["--n-item-icon-color-hover-horizontal"]=r.itemIconColorHoverHorizontalInverted,s["--n-item-icon-color-active-horizontal"]=r.itemIconColorActiveHorizontalInverted,s["--n-item-icon-color-active-hover-horizontal"]=r.itemIconColorActiveHoverHorizontalInverted,s["--n-item-icon-color-child-active-horizontal"]=r.itemIconColorChildActiveHorizontalInverted,s["--n-item-icon-color-child-active-hover-horizontal"]=r.itemIconColorChildActiveHoverHorizontalInverted,s["--n-arrow-color"]=r.arrowColorInverted,s["--n-arrow-color-hover"]=r.arrowColorHoverInverted,s["--n-arrow-color-active"]=r.arrowColorActiveInverted,s["--n-arrow-color-active-hover"]=r.arrowColorActiveHoverInverted,s["--n-arrow-color-child-active"]=r.arrowColorChildActiveInverted,s["--n-arrow-color-child-active-hover"]=r.arrowColorChildActiveHoverInverted,s["--n-item-color-hover"]=r.itemColorHoverInverted,s["--n-item-color-active"]=r.itemColorActiveInverted,s["--n-item-color-active-hover"]=r.itemColorActiveHoverInverted,s["--n-item-color-active-collapsed"]=r.itemColorActiveCollapsedInverted):(s["--n-group-text-color"]=r.groupTextColor,s["--n-color"]=r.color,s["--n-item-text-color"]=r.itemTextColor,s["--n-item-text-color-hover"]=r.itemTextColorHover,s["--n-item-text-color-active"]=r.itemTextColorActive,s["--n-item-text-color-child-active"]=r.itemTextColorChildActive,s["--n-item-text-color-child-active-hover"]=r.itemTextColorChildActiveHover,s["--n-item-text-color-active-hover"]=r.itemTextColorActiveHover,s["--n-item-icon-color"]=r.itemIconColor,s["--n-item-icon-color-hover"]=r.itemIconColorHover,s["--n-item-icon-color-active"]=r.itemIconColorActive,s["--n-item-icon-color-active-hover"]=r.itemIconColorActiveHover,s["--n-item-icon-color-child-active"]=r.itemIconColorChildActive,s["--n-item-icon-color-child-active-hover"]=r.itemIconColorChildActiveHover,s["--n-item-icon-color-collapsed"]=r.itemIconColorCollapsed,s["--n-item-text-color-horizontal"]=r.itemTextColorHorizontal,s["--n-item-text-color-hover-horizontal"]=r.itemTextColorHoverHorizontal,s["--n-item-text-color-active-horizontal"]=r.itemTextColorActiveHorizontal,s["--n-item-text-color-child-active-horizontal"]=r.itemTextColorChildActiveHorizontal,s["--n-item-text-color-child-active-hover-horizontal"]=r.itemTextColorChildActiveHoverHorizontal,s["--n-item-text-color-active-hover-horizontal"]=r.itemTextColorActiveHoverHorizontal,s["--n-item-icon-color-horizontal"]=r.itemIconColorHorizontal,s["--n-item-icon-color-hover-horizontal"]=r.itemIconColorHoverHorizontal,s["--n-item-icon-color-active-horizontal"]=r.itemIconColorActiveHorizontal,s["--n-item-icon-color-active-hover-horizontal"]=r.itemIconColorActiveHoverHorizontal,s["--n-item-icon-color-child-active-horizontal"]=r.itemIconColorChildActiveHorizontal,s["--n-item-icon-color-child-active-hover-horizontal"]=r.itemIconColorChildActiveHoverHorizontal,s["--n-arrow-color"]=r.arrowColor,s["--n-arrow-color-hover"]=r.arrowColorHover,s["--n-arrow-color-active"]=r.arrowColorActive,s["--n-arrow-color-active-hover"]=r.arrowColorActiveHover,s["--n-arrow-color-child-active"]=r.arrowColorChildActive,s["--n-arrow-color-child-active-hover"]=r.arrowColorChildActiveHover,s["--n-item-color-hover"]=r.itemColorHover,s["--n-item-color-active"]=r.itemColorActive,s["--n-item-color-active-hover"]=r.itemColorActiveHover,s["--n-item-color-active-collapsed"]=r.itemColorActiveCollapsed),s}),H=t?(0,u.R)("menu",(0,a.EW)(()=>e.inverted?"a":"b"),k,e):void 0,P=(0,r.sX)(),M=(0,a.KR)(null),W=(0,a.KR)(null),$=!0,O=()=>{var e;$?$=!1:null==(e=M.value)||e.sync({showAllItemsBeforeCalculate:!0})},F=(0,a.KR)(-1),L=(0,a.EW)(()=>{let o=F.value;return{children:-1===o?[]:e.options.slice(o)}}),j=(0,a.EW)(()=>{let{childrenField:o,disabledField:t,keyField:r}=e;return(0,l.G)([L.value],{getIgnored:e=>V(e),getChildren:e=>e[o],getDisabled:e=>e[t],getKey(e){var o;return null!=(o=e[r])?o:e.name}})}),_=(0,a.EW)(()=>(0,l.G)([{}]).treeNodes[0]);return{mergedClsPrefix:o,controlledExpandedKeys:I,uncontrolledExpanededKeys:A,mergedExpandedKeys:B,uncontrolledValue:y,mergedValue:w,activePath:N,tmNodes:T,mergedTheme:c,mergedCollapsed:g,cssVars:t?void 0:k,themeClass:null==H?void 0:H.themeClass,overflowRef:M,counterRef:W,updateCounter:()=>{},onResize:O,onUpdateOverflow:function(e){e||(F.value=-1)},onUpdateCount:function(o){F.value=e.options.length-o},renderCounter:function(){var e;if(-1===F.value)return(0,a.h)(Y,{root:!0,level:0,key:"__ellpisisGroupPlaceholder__",internalKey:"__ellpisisGroupPlaceholder__",title:"\xb7\xb7\xb7",tmNode:_.value,domId:P,isEllipsisPlaceholder:!0});let o=j.value.treeNodes[0],t=N.value,r=!!(null==(e=o.children)?void 0:e.some(e=>t.includes(e.key)));return(0,a.h)(Y,{level:0,root:!0,key:"__ellpisisGroup__",internalKey:"__ellpisisGroup__",title:"\xb7\xb7\xb7",virtualChildActive:r,tmNode:o,domId:P,rawNodes:o.rawNode.children||[],tmNodes:o.children||[],isEllipsisPlaceholder:!0})},getCounter:function(){return document.getElementById(P)},onRender:null==H?void 0:H.onRender,showOption:o=>{let t=x.value.getPath(null!=o?o:w.value,{includeSelf:!1}).keyPath;if(!t.length)return;let r=new Set([...Array.from(B.value),...t]);e.accordion&&f.value.forEach(e=>{r.has(e)&&!t.includes(e)&&r.delete(e)}),R(Array.from(r))},deriveResponsiveState:O}},render(){let{mergedClsPrefix:e,mode:o,themeClass:t,onRender:r}=this;null==r||r();let l=()=>this.tmNodes.map(e=>G(e,this.$props)),i="horizontal"===o&&this.responsive,n=()=>(0,a.h)("div",(0,a.v6)(this.$attrs,{role:"horizontal"===o?"menubar":"menu",class:[`${e}-menu`,t,`${e}-menu--${o}`,i&&`${e}-menu--responsive`,this.mergedCollapsed&&`${e}-menu--collapsed`],style:this.cssVars}),i?(0,a.h)(c.A,{ref:"overflowRef",onUpdateOverflow:this.onUpdateOverflow,getCounter:this.getCounter,onUpdateCount:this.onUpdateCount,updateCounter:this.updateCounter,style:{width:"100%",display:"flex",overflow:"hidden"}},{default:l,counter:this.renderCounter}):l());return i?(0,a.h)(d.A,{onResize:this.onResize},{default:n}):n()}})}}]);