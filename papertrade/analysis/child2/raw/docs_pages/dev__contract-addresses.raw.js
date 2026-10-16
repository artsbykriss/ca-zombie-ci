dev/contract-addresses":{title:`Contract addresses`,eyebrow:`Developer reference`,lead:`Papertrade's contracts on HyperEVM mainnet (chain 999).`,body:`
      <p>Each address links to HyperEVMScan. The Papertrade contracts are proxies; the addresses below are the ones to call.</p>
      <ul>
        <li><strong>Exchange</strong>: balances, positions, settlement and the payout queue.<br><a href="https://hyperevmscan.io/address/0x6cd5661646289FB6E65EA5C032310fDEd797D0a2"><code>0x6cd5661646289FB6E65EA5C032310fDEd797D0a2</code></a></li>
        <li><strong>BatchExecutor</strong>: submits batches of signed user intents to the Exchange.<br><a href="https://hyperevmscan.io/address/0x233Ff29b239abc1D7748605dA9b205C3e008626E"><code>0x233Ff29b239abc1D7748605dA9b205C3e008626E</code></a></li>
        <li><strong>PriceOracle</strong>: reads Hyperliquid's BBO for execution prices.<br><a href="https://hyperevmscan.io/address/0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e"><code>0xa9B4c7b7Ca5835652d81E25739c870D49F39cC2e</code></a></li>
        <li><strong>SessionKeyManager</strong>: registers, checks and revokes session keys.<br><a href="https://hyperevmscan.io/address/0x8326Eb8896e358717f10502Ec73CE8D28E37B108"><code>0x8326Eb8896e358717f10502Ec73CE8D28E37B108</code></a></li>
        <li><strong>DepositProxyFactory</strong>: derives and deploys each user's deposit address.<br><a href="https://hyperevmscan.io/address/0x1629b7D46bef6E13FF754174FC9F32dEa309b38F"><code>0x1629b7D46bef6E13FF754174FC9F32dEa309b38F</code></a></li>
        <li><strong>PaperToken</strong>: the PAPER token.<br><a href="https://hyperevmscan.io/address/0xe40f17915DAa230324030003A197cdAEf2261C0e"><code>0xe40f17915DAa230324030003A197cdAEf2261C0e</code></a></li>
        <li><strong>PaperStaking</strong>: PAPER staking and USDC rewards.<br><a href="https://hyperevmscan.io/address/0xAAd6c7b0CC3014FC80FfEDAe0Ed7Ce5967b0F016"><code>0xAAd6c7b0CC3014FC80FfEDAe0Ed7Ce5967b0F016</code></a></li>
        <li><strong>PaperTokenomics</strong>: the PAPER mint curve and staker LP excess.<br><a href="https://hyperevmscan.io/address/0x75174549dbBD44497D31a47E2E2D7406408d63D9"><code>0x75174549dbBD44497D31a47E2E2D7406408d63D9</code></a></li>
      </ul>

      <h2 id="governance">Collateral and governance</h2>
      <ul>
        <li><strong>USDC</strong>: the collateral token, native Circle USDC on HyperEVM.<br><a href="https://hyperevmscan.io/address/0xb88339CB7199b77E23DB6E890353E22632Ba630f"><code>0xb88339CB7199b77E23DB6E890353E22632Ba630f</code></a></li>
        <li><strong>Timelock</strong>: owns the contracts; every owner action waits 7 days here before it can run.<br><a href="https://hyperevmscan.io/address/0xB915Fa41e824D6aA31BB833Ee81220C0F2c8EA0F"><code>0xB915Fa41e824D6aA31BB833Ee81220C0F2c8EA0F</code></a></li>
        <li><strong>Multisig</strong>: a 2-of-3 multisig that owns the Timelock; only it can schedule, execute or cancel an owner action.<br><a href="https://hyperevmscan.io/address/0x696292762fD5AC3677a45EdBe54EAECE4194d1F6"><code>0x696292762fD5AC3677a45EdBe54EAECE4194d1F6</code></a></li>
      </ul>
    `}};function r(){let e=location.hash||``;return e?e.startsWith(`#/`)?e.replace(/^#\//,``).replace(/\/$/,``)||t:null:t}function i(){return e.flatMap(e=>e.items)}function a(e){let t=i(),n=t.findIndex(t=>t.slug===e);return{prev:n>0?t[n-1]:null,next:n>=0&&n<t.length-1?t[n+1]:null}}function o(t){let[n,r]=t.split(`/`),i=e.find(e=>e.items.some(e=>e.slug.startsWith(n+`/`)));return i?i.label:`Docs`}function s(t){let n=document.getElementById(`sidebarNav`);n.innerHTML=e.map(e=>`
    <div class="sidebar-section">
      <p class="sidebar-head">${e.label}</p>
      <ul class="sidebar-list">
        ${e.items.map(e=>`
          <li><a href="#/${e.slug}" class="${e.slug===t?`active`:``}" data-slug="${e.slug}">${e.title}</a></li>
        `).join(``)}
      </ul>
    </div>
  `).join(``)}function c(){let e=document.querySelector(`.article`),t=document.getElementById(`tocList`);if(!e||!t)return;let n=e.querySelectorAll(`h2, h3`);if(!n.length){t.innerHTML=``;return}t.innerHTML=Array.from(n).map(e=>{e.id||=e.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g,`-`).replace(/^-|-$/g,``);let t=e.tagName===`H3`?`h3`:``;return`<li><a href="#${e.id}" class="${t}" data-heading="${e.id}">${e.textContent}</a></li>`}).join(``),u(n)}var l=null;function u(e){l&&l.disconnect();let t=new Map;l=new IntersectionObserver(e=>{e.forEach(e=>t.set(e.target.id,e.isIntersecting));let n=Array.from(t.entries()).filter(([,e])=>e).map(([e])=>e)[0]||null;document.querySelectorAll(`#tocList a`).forEach(e=>{e.classList.toggle(`active`,e.getAttribute(`data-heading`)===n)})},{rootMargin:`-80px 0px -70% 0px`,threshold:0}),e.forEach(e=>l.observe(e))}function d(e){let r=document.getElementById(`article`),i=n[e];if(!i){r.innerHTML=`
      <div class="not-found">
        <div class="breadcrumb"><a href="#/">Docs</a><span class="sep">/</span><span>404</span></div>
        <h1>Page not found</h1>
        <p>We couldn't find <code>${e}</code>.</p>
        <a class="back" href="#/${t}">← Back to docs home</a>
      </div>
    `,document.getElementById(`tocList`).innerHTML=``;return}let{prev:s,next:l}=a(e);r.innerHTML=`
    <div class="breadcrumb">
      <a href="#/${t}">Docs</a>
      <span class="sep">/</span>
      <span>${o(e)}</span>
      <span class="sep">/</span>
      <span>${i.title}</span>
    </div>
    <article class="article">
      ${i.eyebrow?`<div class="eyebrow">${i.eyebrow}</div>`:``}
      <h1>${i.title}</h1>
      ${i.lead?`<p class="lead">${i.lead}</p>`:``}
      ${i.body}
      <div class="prev-next">
        ${s?`<a href="#/${s.slug}"><div class="label">← Previous</div><div class="title">${s.title}</div></a>`:`<a class="disabled" aria-disabled="true"><div class="label">← Previous</div><div class="title">…</div></a>`}
        ${l?`<a class="next" href="#/${l.slug}"><div class="label">Next →</div><div class="title">${l.title}</div></a>`:`<a class="next disabled" aria-disabled="true"><div class="label">Next →</div><div class="title">…</div></a>`}
      </div>
      <div class="article-foot">
        <span>Last updated: <time>2026-10-06</time></span>
      </div>
    </article>
  `,c(),window.scrollTo({top:0,behavior:`instant`}),document.title=`${i.title} · Papertrade Docs`}function f(){let e=document.getElementById(`sidebarToggle`),t=document.getElementById(`sidebar`);if(!e||!t)return;let n=n=>{t.classList.toggle(`is-collapsed`,!n),e.setAttribute(`aria-expanded`,n?`true`:`false`)};e.addEventListener(`click`,()=>{n(t.classList.contains(`is-collapsed`))}),t.addEventListener(`click`,e=>{e.target.tagName===`A`&&e.target.dataset.slug&&n(!1)});let r=()=>{window.matchMedia(`(min-width:900px)`).matches?t.classList.remove(`is-collapsed`):e.getAttribute(`aria-expanded`)!==`true`&&t.classList.add(`is-collapsed`)};window.addEventListener(`resize`,r),r()}function p(){document.addEventListener(`keydown`,e=>{if(e.target.tagName===`INPUT`||e.target.tagName===`TEXTAREA`||e.metaKey||e.ctrlKey||e.altKey)return;let{prev:t,next:n}=a(r());e.key===`[`&&t&&(location.hash=`#/`+t.slug,e.preventDefault()),e.key===`]`&&n&&(location.hash=`#/`+n.slug,e.preventDefault())})}function m(){let e=r();e!==null&&(s(e),d(e))}window.addEventListener(`hashchange`,m),window.addEventListener(`load`,()=>{f(),p(),m()});