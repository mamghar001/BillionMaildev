"use strict";(self.webpackChunkfrontend=self.webpackChunkfrontend||[]).push([["3355"],{90662(e,r,t){t.r(r),t.d(r,{default:()=>u});var a=t(29252),o=t(4374),n=t(90290),l=t(12532);let i={class:"h-full p-20px"},s=["src"],c=(0,n.pM)({__name:"index",setup(e){let r=(0,n.KR)(`${window.location.origin}${l.Cu?"/api":""}/rspamd/`);return(e,t)=>{let l=(0,n.g2)("router-link"),c=o.A,u=a.Ay;return(0,n.uX)(),(0,n.CE)("div",i,[(0,n.bF)(u,{class:"mb-16px"},{default:(0,n.k6)(()=>[(0,n.bF)(c,null,{default:(0,n.k6)(()=>[(0,n.bF)(l,{to:"/settings"},{default:(0,n.k6)(()=>[(0,n.eW)((0,n.v_)(e.$t("layout.menu.settings")),1)]),_:1})]),_:1}),(0,n.bF)(c,null,{default:(0,n.k6)(()=>[(0,n.bF)(l,{to:"/settings/service"},{default:(0,n.k6)(()=>[(0,n.eW)((0,n.v_)(e.$t("layout.menu.service")),1)]),_:1})]),_:1}),(0,n.bF)(c,null,{default:(0,n.k6)(()=>[...t[0]||(t[0]=[(0,n.eW)("Rspamd",-1)])]),_:1})]),_:1}),(0,n.Lk)("iframe",{class:"w-full",src:(0,n.R1)(r)},null,8,s)])}}}),u=(0,t(64901).default)(c,[["__scopeId","data-v-8cf9b823"]])},29252(e,r,t){t.d(r,{s7:()=>d,Ay:()=>m});var a=t(90290),o=t(49359),n=t(50922),l=t(4019),i=t(29794),s=t(23766),c=t(75454);let u=(0,c.cB)("breadcrumb",`
 white-space: nowrap;
 cursor: default;
 line-height: var(--n-item-line-height);
`,[(0,c.c)("ul",`
 list-style: none;
 padding: 0;
 margin: 0;
 `),(0,c.c)("a",`
 color: inherit;
 text-decoration: inherit;
 `),(0,c.cB)("breadcrumb-item",`
 font-size: var(--n-font-size);
 transition: color .3s var(--n-bezier);
 display: inline-flex;
 align-items: center;
 `,[(0,c.cB)("icon",`
 font-size: 18px;
 vertical-align: -.2em;
 transition: color .3s var(--n-bezier);
 color: var(--n-item-text-color);
 `),(0,c.c)("&:not(:last-child)",[(0,c.cM)("clickable",[(0,c.cE)("link",`
 cursor: pointer;
 `,[(0,c.c)("&:hover",`
 background-color: var(--n-item-color-hover);
 `),(0,c.c)("&:active",`
 background-color: var(--n-item-color-pressed); 
 `)])])]),(0,c.cE)("link",`
 padding: 4px;
 border-radius: var(--n-item-border-radius);
 transition:
 background-color .3s var(--n-bezier),
 color .3s var(--n-bezier);
 color: var(--n-item-text-color);
 position: relative;
 `,[(0,c.c)("&:hover",`
 color: var(--n-item-text-color-hover);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-hover);
 `)]),(0,c.c)("&:active",`
 color: var(--n-item-text-color-pressed);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-pressed);
 `)])]),(0,c.cE)("separator",`
 margin: 0 8px;
 color: var(--n-separator-color);
 transition: color .3s var(--n-bezier);
 user-select: none;
 -webkit-user-select: none;
 `),(0,c.c)("&:last-child",[(0,c.cE)("link",`
 font-weight: var(--n-font-weight-active);
 cursor: unset;
 color: var(--n-item-text-color-active);
 `,[(0,c.cB)("icon",`
 color: var(--n-item-text-color-active);
 `)]),(0,c.cE)("separator",`
 display: none;
 `)])])]),d=(0,i.D)("n-breadcrumb"),v=Object.assign(Object.assign({},o.A.props),{separator:{type:String,default:"/"}}),m=(0,a.pM)({name:"Breadcrumb",props:v,setup(e){let{mergedClsPrefixRef:r,inlineThemeDisabled:t}=(0,n.Ay)(e),i=(0,o.A)("Breadcrumb","-breadcrumb",u,s.A,e,r);(0,a.Gt)(d,{separatorRef:(0,a.lW)(e,"separator"),mergedClsPrefixRef:r});let c=(0,a.EW)(()=>{let{common:{cubicBezierEaseInOut:e},self:{separatorColor:r,itemTextColor:t,itemTextColorHover:a,itemTextColorPressed:o,itemTextColorActive:n,fontSize:l,fontWeightActive:s,itemBorderRadius:c,itemColorHover:u,itemColorPressed:d,itemLineHeight:v}}=i.value;return{"--n-font-size":l,"--n-bezier":e,"--n-item-text-color":t,"--n-item-text-color-hover":a,"--n-item-text-color-pressed":o,"--n-item-text-color-active":n,"--n-separator-color":r,"--n-item-color-hover":u,"--n-item-color-pressed":d,"--n-item-border-radius":c,"--n-font-weight-active":s,"--n-item-line-height":v}}),v=t?(0,l.R)("breadcrumb",void 0,c,e):void 0;return{mergedClsPrefix:r,cssVars:t?void 0:c,themeClass:null==v?void 0:v.themeClass,onRender:null==v?void 0:v.onRender}},render(){var e;return null==(e=this.onRender)||e.call(this),(0,a.h)("nav",{class:[`${this.mergedClsPrefix}-breadcrumb`,this.themeClass],style:this.cssVars,"aria-label":"Breadcrumb"},(0,a.h)("ul",null,this.$slots))}})},4374(e,r,t){t.d(r,{A:()=>i});var a=t(90290),o=t(49521),n=t(91900),l=t(29252);let i=(0,a.pM)({name:"BreadcrumbItem",props:{separator:String,href:String,clickable:{type:Boolean,default:!0},showSeparator:{type:Boolean,default:!0},onClick:Function},slots:Object,setup(e,{slots:r}){let t=(0,a.WQ)(l.s7,null);if(!t)return()=>null;let{separatorRef:i,mergedClsPrefixRef:s}=t,c=function(e=n.B?window:null){let r=()=>{let{hash:r,host:t,hostname:a,href:o,origin:n,pathname:l,port:i,protocol:s,search:c}=(null==e?void 0:e.location)||{};return{hash:r,host:t,hostname:a,href:o,origin:n,pathname:l,port:i,protocol:s,search:c}},t=(0,a.KR)(r()),o=()=>{t.value=r()};return(0,a.sV)(()=>{e&&(e.addEventListener("popstate",o),e.addEventListener("hashchange",o))}),(0,a.hi)(()=>{e&&(e.removeEventListener("popstate",o),e.removeEventListener("hashchange",o))}),t}(),u=(0,a.EW)(()=>e.href?"a":"span"),d=(0,a.EW)(()=>c.value.href===e.href?"location":null);return()=>{let{value:t}=s;return(0,a.h)("li",{class:[`${t}-breadcrumb-item`,e.clickable&&`${t}-breadcrumb-item--clickable`]},(0,a.h)(u.value,{class:`${t}-breadcrumb-item__link`,"aria-current":d.value,href:e.href,onClick:e.onClick},r),e.showSeparator&&(0,a.h)("span",{class:`${t}-breadcrumb-item__separator`,"aria-hidden":"true"},(0,o.Nj)(r.separator,()=>{var r;return[null!=(r=e.separator)?r:i.value]})))}}})}}]);