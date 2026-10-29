// Run with Node.js and Playwright installed. Uses a fresh, headless browser profile.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const os = require('node:os');
const { pathToFileURL } = require('node:url');
const output = path.resolve(process.argv[2] || path.join(os.tmpdir(), 'barotrauma-menu-preview'));
(async () => {
  await fs.mkdir(output, { recursive: true });
  const browser = await chromium.launch({ channel: 'msedge', headless: true, ignoreDefaultArgs: ['--hide-scrollbars'] });
  const errors = [];
  const measurements = [];
  try {
    const page = await browser.newPage({ viewport: { width: 1000, height: 900 }, deviceScaleFactor: 1 });
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('requestfailed', request => errors.push(request.url() + ': ' + request.failure()?.errorText));
    // Both prototypes must clamp only after editing ends, including very large input.
    for (const [label, file] of [['item-row', '../item-row/prototype.html'], ['menu', 'prototype.html']]) {
      const url = pathToFileURL(path.join(__dirname, file)).href;
      await page.goto(url);
      const row = page.locator('.item-row[data-name="Алюминий"]');
      const input = row.locator('.quantity');
      for (const width of [1000, 390]) {
        await page.setViewportSize({ width, height: 900 });
        await input.fill('100');
        assert.equal(await input.inputValue(), '100', label + ': preserve unfinished input');
        await input.press('Tab');
        assert.equal(await input.inputValue(), '54', label + ': clamp on blur');
        assert.equal(await row.getAttribute('data-stock'), '54', label + ': blur must not take items');
        await page.screenshot({ path: path.join(output, label + '-quantity-' + width + '.png'), fullPage: true });
      }
      await input.fill('12');
      await input.press('Tab');
      assert.equal(await input.inputValue(), '12', label + ': preserve valid quantity');
      await input.fill('999999999999999999999999999999999999999');
      await input.press('Tab');
      assert.equal(await input.inputValue(), '54', label + ': clamp huge integers');
      for (const value of ['', '0', '-1', '1.5']) {
        await input.fill(value);
        await input.press('Tab');
        assert.equal(await input.inputValue(), value, label + ': leave unrelated input rules unchanged');
      }
      await input.fill('100');
      await input.press('Enter');
      assert.equal(await input.inputValue(), '54', label + ': clamp on submit');
      assert.equal(await row.getAttribute('data-stock'), '0', label + ': take only stock');
      assert.equal(await row.isVisible(), false);
      await page.reload();
      await input.fill('40');
      await row.getByRole('button', { name: 'Взять', exact: true }).click();
      assert.equal(await row.getAttribute('data-stock'), '14');
      assert.equal(await input.inputValue(), '40', label + ': preserve input after taking');
      await input.fill('100');
      await input.press('Tab');
      assert.equal(await input.inputValue(), '14', label + ': use current stock');
    }
    await page.setViewportSize({ width: 1000, height: 900 });
    await page.goto(pathToFileURL(path.join(__dirname, 'prototype.html')).href);
    await page.waitForLoadState('networkidle');
    for (const width of [1000, 621, 620, 390, 320]) {
      await page.setViewportSize({ width, height: 900 });
      await page.screenshot({ path: path.join(output, 'menu-' + width + '.png'), fullPage: true });
      const layout = await page.evaluate(() => {
        const issues = [];
        const box = element => element.getBoundingClientRect();
        const overlaps = (a, b) => Math.min(a.right,b.right)-Math.max(a.left,b.left)>1 && Math.min(a.bottom,b.bottom)-Math.max(a.top,b.top)>1;
        if (document.documentElement.scrollWidth > innerWidth) issues.push('Page overflows horizontally');
        for (const row of document.querySelectorAll('.item-row')) {
          const bounds = box(row);
          const children = [...row.children];
          for (const child of children) {
            const b = box(child);
            if (b.left < bounds.left-1 || b.right > bounds.right+1 || b.top < bounds.top-1 || b.bottom > bounds.bottom+1) issues.push(row.dataset.name + ': outside row: ' + child.className);
          }
          for (let i=0;i<children.length;i++) for(let j=i+1;j<children.length;j++) {
            if(overlaps(box(children[i]),box(children[j]))) issues.push(row.dataset.name + ': overlap: ' + children[i].className + ' / ' + children[j].className);
          }
        }
        return { width: innerWidth, rowHeight: box(document.querySelector('.item-row')).height, issues };
      });
      measurements.push(layout);
      assert.deepEqual(layout.issues, [], 'Layout at ' + width);
      await page.getByRole('button', { name: 'Категории', exact: true }).click();
      const categoryList = page.locator('.categories');
      assert.equal(await categoryList.getByRole('checkbox').count(), 9);
      assert.equal(await categoryList.evaluate(list => list.scrollHeight > list.clientHeight), true, 'Category list must scroll');
      assert.equal(await categoryList.evaluate(list => list.scrollWidth <= list.clientWidth), true, 'No horizontal clipping');
      assert.equal(await categoryList.evaluate(list => {
        const labels = [...list.querySelectorAll('label')].map(label => label.getBoundingClientRect());
        return labels.every((box, index) => index === 0 || (box.top >= labels[index-1].bottom && Math.abs(box.left-labels[0].left) < 1));
      }), true, 'Categories form one vertical column');
      await categoryList.evaluate(list => { list.scrollTop = 0; });
      await page.screenshot({ path: path.join(output, 'categories-' + width + '.png'), fullPage: true });
      await categoryList.getByLabel('Прочее', { exact: true }).check();
      assert.equal(await categoryList.getByLabel('Прочее', { exact: true }).isChecked(), true);
      assert.ok(await categoryList.evaluate(list => list.scrollTop > 0), 'Last category reachable by scrolling');
      await page.screenshot({ path: path.join(output, 'categories-bottom-' + width + '.png'), fullPage: true });
      await categoryList.getByLabel('Прочее', { exact: true }).uncheck();
      await categoryList.evaluate(list => { list.scrollTop = 0; });
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true);
      await page.getByRole('button', { name: 'Категории', exact: true }).click();
    }
    await page.setViewportSize({ width: 1000, height: 900 });
    const search = page.getByRole('searchbox', { name: 'Поиск по названию' });
    await search.fill('плаз');
    assert.deepEqual(await page.locator('.item-row:visible').evaluateAll(rows => rows.map(row => row.dataset.name)), ['Плазморез']);
    await search.fill('несуществующий предмет');
    assert.equal(await page.locator('.item-row:visible').count(), 0);
    assert.equal((await page.locator('.item-list').innerText()).trim(), '');
    await page.screenshot({ path: path.join(output, 'empty-search.png'), fullPage: true });
    await search.fill('');
    await page.getByRole('button', { name: 'Категории', exact: true }).click();
    await page.getByLabel('Материалы', { exact: true }).check();
    await page.getByLabel('Инструменты', { exact: true }).check();
    const categoryToggle = page.getByRole('button', { name: 'Категории', exact: true });
    assert.equal(await categoryToggle.locator('svg').count(), 1, 'Icon survives category selection');
    assert.equal((await categoryToggle.innerText()).trim(), '', 'Button stays icon-only');
    await categoryToggle.click();
    assert.equal(await page.locator('.categories').isVisible(), false);
    await categoryToggle.click();
    assert.equal(await page.getByLabel('Материалы', { exact: true }).isChecked(), true);
    assert.equal(await page.getByLabel('Инструменты', { exact: true }).isChecked(), true);
    assert.deepEqual(await page.locator('.item-row:visible').evaluateAll(rows => rows.map(row => row.dataset.name)), ['Алюминий', 'Плазморез']);
    await search.fill('плаз');
    assert.equal(await page.locator('.item-row:visible').count(), 1);
    await page.reload();
    const tool = page.locator('.item-row[data-name="Плазморез"]');
    await tool.locator('.favorite').click();
    assert.deepEqual(await page.locator('.item-row').evaluateAll(rows => rows.slice(0,2).map(row => row.dataset.name)), ['Алюминий', 'Плазморез']);
    const aluminium = page.locator('.item-row[data-name="Алюминий"]');
    await aluminium.locator('.quantity').fill('3');
    await aluminium.getByRole('button', { name: 'Взять', exact: true }).click();
    assert.equal(await aluminium.getAttribute('data-stock'), '51');
    assert.equal(await aluminium.locator('.quantity').inputValue(), '3');
    await tool.getByRole('button', { name: 'Взять', exact: true }).click();
    assert.equal(await tool.isVisible(), false);
    await page.reload();
    await page.locator('.item-list').evaluate(list => { list.scrollTop = list.scrollHeight; });
    assert.ok(await page.locator('.item-list').evaluate(list => list.scrollTop > 0));
    await page.screenshot({ path: path.join(output, 'menu-scrolled.png'), fullPage: true });
    const slots = page.locator('.item-row[data-name="Экзокостюм"] .inserted-items');
    await slots.focus();
    await slots.press('End');
    assert.ok(await slots.evaluate(strip => strip.scrollLeft > 0));
    await page.screenshot({ path: path.join(output, 'slots-scrolled.png'), fullPage: true });
    await page.reload();
    await page.screenshot({ path: path.join(output, 'menu-preview.png'), fullPage: true });

    // Favorites window: shared state, absent types, search, drag, and constrained viewports.
    const favoritesToggle = page.getByRole('button', { name: 'Настроить избранное', exact: true });
    const popup = page.getByRole('dialog', { name: 'Избранное', exact: true });
    for (const width of [1000,390,320]) {
      await page.setViewportSize({ width, height: 900 });
      await favoritesToggle.click();
      assert.equal(await popup.isVisible(), true);
      assert.equal(await popup.getByRole('listitem').count(), 3);
      assert.equal(await page.locator('.item-row[data-name="Аккумулятор"]').count(), 0, 'Absent favorite must not create stock');
      await page.screenshot({ path: path.join(output, 'favorites-' + width + '.png'), fullPage: true });
      await popup.getByRole('button', { name: 'Добавить', exact: true }).click();
      const typeSearch = popup.getByRole('searchbox', { name: 'Поиск по всем типам предметов' });
      await typeSearch.fill('плаз');
      await page.screenshot({ path: path.join(output, 'favorites-search-' + width + '.png'), fullPage: true });
      assert.equal(await popup.evaluate(el => {
        const r=el.getBoundingClientRect();
        return r.left>=0 && r.top>=0 && r.right<=document.documentElement.clientWidth && r.bottom<=innerHeight && el.scrollWidth<=el.clientWidth;
      }), true, 'Popup fits viewport at '+width);
      await popup.getByRole('button', {name: 'Добавить в избранное: Плазморез',exact:true}).click();
      assert.equal(await popup.getByRole('listitem').count(), 4);
      assert.equal(await page.locator('.item-row[data-name="Плазморез"] .favorite').getAttribute('aria-pressed'),'true');
      assert.equal(await popup.getByRole('button', { name: 'Уже в избранном: Плазморез',exact:true }).isDisabled(),true);
      await popup.getByRole('button', { name: 'Убрать из избранного: Плазморез',exact:true }).click();
      assert.equal(await page.locator('.item-row[data-name="Плазморез"] .favorite').getAttribute('aria-pressed'),'false');
      await typeSearch.fill('неттакогопредмета');
      assert.equal(await popup.locator('.favorite-search-hint').innerText(),'Ничего не найдено');
      await page.keyboard.press('Escape');
      assert.equal(await popup.isVisible(),false);
      await page.reload();
    }
    await page.setViewportSize({width:1000,height:900});
    await favoritesToggle.click();
    await page.locator('.item-row[data-name="Алюминий"] .favorite').click();
    assert.equal(await popup.getByRole('button',{name:'Убрать из избранного: Алюминий',exact:true}).count(),0,'Row changes update open dialog');
    await page.locator('.item-row[data-name="Алюминий"] .favorite').click();
    assert.equal(await popup.getByRole('button',{name:'Убрать из избранного: Алюминий',exact:true}).count(),1);
    const beforeDrag=await popup.boundingBox();
    const header=await popup.locator('.favorites-header').boundingBox();
    await page.mouse.move(header.x+100,header.y+20); await page.mouse.down();
    await page.mouse.move(header.x+180,header.y+70,{steps:8}); await page.mouse.up();
    const afterDrag=await popup.boundingBox();
    assert.ok(Math.abs(afterDrag.x-beforeDrag.x-80)<2 && Math.abs(afterDrag.y-beforeDrag.y-50)<2,'Drag moves popup');
    await page.mouse.move(afterDrag.x+100,afterDrag.y+20); await page.mouse.down();
    await page.mouse.move(999,899,{steps:8}); await page.mouse.up();
    assert.equal(await popup.evaluate(el=>{const r=el.getBoundingClientRect();return r.right<=document.documentElement.clientWidth && r.bottom<=innerHeight;}),true,'Drag remains onscreen');
    await popup.getByRole('button',{name:'Добавить',exact:true}).click();
    const typeSearch=popup.getByRole('searchbox',{name:'Поиск по всем типам предметов'});
    await typeSearch.fill('Топливный');
    await popup.getByRole('button',{name:'Добавить в избранное: Топливный стержень',exact:true}).click();
    assert.equal(await page.locator('.item-row[data-name="Топливный стержень"]').count(),0);
    await popup.getByRole('button',{name:'Закрыть избранное',exact:true}).click();
    await favoritesToggle.click();
    assert.equal(await popup.getByRole('button',{name:'Убрать из избранного: Топливный стержень',exact:true}).count(),1,'Favorites persist when closed');
    await popup.getByRole('button',{name:'Добавить',exact:true}).click();
    await typeSearch.fill('а');
    while (await popup.getByRole('button',{name:/^Добавить в избранное:/}).count()) await popup.getByRole('button',{name:/^Добавить в избранное:/}).first().click();
    assert.ok(await popup.locator('.favorites-list').evaluate(el=>el.scrollHeight>el.clientHeight),'Favorites list scrolls');
    await page.setViewportSize({width:640,height:360});
    await page.screenshot({path:path.join(output,'favorites-short.png'),fullPage:true});
    assert.equal(await popup.evaluate(el=>{const r=el.getBoundingClientRect();return r.top>=0 && r.bottom<=innerHeight;}),true,'Fits short viewport');
    await page.setViewportSize({width:1000,height:900});
    while (await popup.locator('.favorite-remove').count()) await popup.locator('.favorite-remove').first().click();
    assert.equal(await popup.locator('.favorites-empty').isVisible(),true);
    await popup.getByRole('button',{name:'Закрыть избранное',exact:true}).click();
    await page.reload();

    // Acceptance settings are independent from inventory display and favorites.
    const filtersToggle = page.getByRole('button',{name:'Настроить фильтры приёма',exact:true});
    const filtersPopup = page.getByRole('dialog',{name:'Фильтры приёма',exact:true});
    for(const width of [1000,390,320]) {
      await page.setViewportSize({width,height:900});
      await filtersToggle.click();
      const stockBefore = await page.locator('.item-row').evaluateAll(rows=>rows.map(row=>({name:row.dataset.name,stock:row.dataset.stock,hidden:row.hidden,favorite:row.querySelector('.favorite').getAttribute('aria-pressed')})));
      assert.equal(await filtersPopup.getByRole('radio',{name:'Выключен',exact:true}).isChecked(),true);
      await filtersPopup.getByRole('radio',{name:'Белый список',exact:true}).check();
      assert.match(await filtersPopup.locator('.filter-mode-hint').innerText(),/^Принимать только/);
      await filtersPopup.getByLabel('Применять к вложенным хранилищам',{exact:true}).check();
      await page.screenshot({path:path.join(output,'filters-'+width+'.png'),fullPage:true});
      await filtersPopup.getByRole('radio',{name:'Чёрный список',exact:true}).check();
      assert.match(await filtersPopup.locator('.filter-mode-hint').innerText(),/^Не принимать/);
      await filtersPopup.getByRole('button',{name:'Добавить категорию',exact:true}).click();
      assert.equal(await filtersPopup.getByRole('button',{name:'Категория уже добавлена: Материалы',exact:true}).isDisabled(),true);
      assert.equal(await filtersPopup.locator('.filter-category-options').evaluate(el=>el.scrollHeight>el.clientHeight),true);
      await filtersPopup.getByRole('button',{name:'Добавить категорию: Прочее',exact:true}).click();
      assert.equal(await filtersPopup.getByRole('button',{name:'Удалить из фильтра: Прочее',exact:true}).count(),1);
      await page.screenshot({path:path.join(output,'filters-categories-'+width+'.png'),fullPage:true});
      await filtersPopup.getByRole('button',{name:'Удалить из фильтра: Прочее',exact:true}).click();
      await filtersPopup.getByRole('button',{name:'Добавить категорию',exact:true}).click();
      await filtersPopup.getByRole('button',{name:'Добавить предмет',exact:true}).click();
      const itemSearch=filtersPopup.getByRole('searchbox',{name:'Поиск по всем типам предметов'});
      await itemSearch.fill('акку');
      await page.screenshot({path:path.join(output,'filters-search-'+width+'.png'),fullPage:true});
      await filtersPopup.getByRole('button',{name:'Добавить предмет: Аккумулятор',exact:true}).click();
      assert.equal(await filtersPopup.getByRole('button',{name:'Предмет уже добавлен: Аккумулятор',exact:true}).isDisabled(),true);
      assert.equal(await filtersPopup.getByRole('button',{name:'Удалить из фильтра: Аккумулятор',exact:true}).count(),1);
      await itemSearch.fill('несуществующийпредмет');
      assert.equal(await filtersPopup.locator('.filter-item-hint').innerText(),'Ничего не найдено');
      assert.equal(await filtersPopup.evaluate(el=>{
        const r=el.getBoundingClientRect();
        return r.left>=0 && r.top>=0 && r.right<=document.documentElement.clientWidth && r.bottom<=innerHeight && el.scrollWidth<=el.clientWidth && el.querySelector('.filters-body').scrollWidth<=el.querySelector('.filters-body').clientWidth;
      }),true,'Filter window fits '+width);
      const stockAfter = await page.locator('.item-row').evaluateAll(rows=>rows.map(row=>({name:row.dataset.name,stock:row.dataset.stock,hidden:row.hidden,favorite:row.querySelector('.favorite').getAttribute('aria-pressed')})));
      assert.deepEqual(stockAfter,stockBefore,'Acceptance settings must not change stored items or favorites');
      await filtersPopup.getByRole('button',{name:'Закрыть фильтры приёма',exact:true}).click();
      await filtersToggle.click();
      assert.equal(await filtersPopup.getByRole('radio',{name:'Чёрный список',exact:true}).isChecked(),true);
      assert.equal(await filtersPopup.getByLabel('Применять к вложенным хранилищам',{exact:true}).isChecked(),true);
      assert.equal(await filtersPopup.getByRole('button',{name:'Удалить из фильтра: Аккумулятор',exact:true}).count(),1);
      await filtersPopup.getByRole('radio',{name:'Выключен',exact:true}).check();
      assert.equal(await filtersPopup.getByRole('button',{name:'Удалить из фильтра: Аккумулятор',exact:true}).count(),1,'Switching mode retains entries');
      while(await filtersPopup.locator('.filter-remove').count()) await filtersPopup.locator('.filter-remove').first().click();
      await filtersPopup.getByRole('radio',{name:'Белый список',exact:true}).check();
      assert.equal(await filtersPopup.locator('.filter-mode-hint').innerText(),'Список пуст — приём запрещён.');
      await filtersPopup.getByRole('radio',{name:'Чёрный список',exact:true}).check();
      assert.match(await filtersPopup.locator('.filter-mode-hint').innerText(),/не ограничивает приём/);
      await page.keyboard.press('Escape'); assert.equal(await filtersPopup.isVisible(),false);
      await page.reload();
    }
    await page.setViewportSize({width:1000,height:900});
    await filtersToggle.click();
    const filterBeforeDrag=await filtersPopup.boundingBox();
    const filterHeader=await filtersPopup.locator('.filters-header').boundingBox();
    await page.mouse.move(filterHeader.x+100,filterHeader.y+20); await page.mouse.down();
    await page.mouse.move(filterHeader.x+170,filterHeader.y+60,{steps:6}); await page.mouse.up();
    const filterAfterDrag=await filtersPopup.boundingBox();
    assert.ok(Math.abs(filterAfterDrag.x-filterBeforeDrag.x-70)<2 && Math.abs(filterAfterDrag.y-filterBeforeDrag.y-40)<2);
    await favoritesToggle.click();
    assert.equal(await popup.isVisible(),true); assert.equal(await filtersPopup.isVisible(),true);
    await page.keyboard.press('Escape');
    assert.equal(await popup.isVisible(),false); assert.equal(await filtersPopup.isVisible(),true,'Escape closes only the foreground window');
    await page.setViewportSize({width:640,height:360});
    await page.screenshot({path:path.join(output,'filters-short.png'),fullPage:true});
    assert.equal(await filtersPopup.evaluate(el=>{const r=el.getBoundingClientRect();return r.top>=0 && r.bottom<=innerHeight;}),true);
    await filtersPopup.getByRole('button',{name:'Добавить предмет',exact:true}).click();
    await filtersPopup.getByRole('searchbox',{name:'Поиск по всем типам предметов'}).fill('плаз');
    assert.equal(await filtersPopup.getByRole('button',{name:'Предмет уже добавлен: Плазморез',exact:true}).isDisabled(),true,'Search remains usable on short screens');
    await page.keyboard.press('Escape');
    await page.setViewportSize({width:1000,height:900}); await page.reload();

    // Independent mode color, incoming constraints, and propagation of own filter.
    const modeLabels={off:'Выключен',allow:'Белый список',deny:'Чёрный список'};
    const modeColors={off:'rgb(138, 150, 153)',allow:'rgb(143, 198, 162)',deny:'rgb(213, 140, 117)'};
    const iconStates=[];
    for(const inherited of [false,true]) {
      const scenario=pathToFileURL(path.join(__dirname,'prototype.html'));
      if(inherited) scenario.searchParams.set('inherited','1');
      await page.goto(scenario.href);
      await filtersToggle.click();
      for(const mode of ['off','allow','deny']) {
        await filtersPopup.getByRole('radio',{name:modeLabels[mode],exact:true}).check();
        for(const nested of [false,true]) {
          await filtersPopup.getByLabel('Применять к вложенным хранилищам',{exact:true}).setChecked(nested);
          const propagating=mode!=='off' && nested;
          assert.equal(await filtersToggle.getAttribute('data-mode'),mode);
          assert.equal(await filtersToggle.getAttribute('data-inherited'),String(inherited));
          assert.equal(await filtersToggle.getAttribute('data-propagating'),String(propagating));
          assert.equal(await filtersToggle.locator('.filter-symbol').evaluate(el=>getComputedStyle(el).color),modeColors[mode]);
          assert.equal(await filtersToggle.locator('.filter-arrow-up').evaluate(el=>getComputedStyle(el).fill),inherited?'rgb(232, 221, 190)':'rgb(88, 102, 106)');
          assert.equal(await filtersToggle.locator('.filter-arrow-down').evaluate(el=>getComputedStyle(el).fill),propagating?'rgb(232, 221, 190)':'rgb(88, 102, 106)');
          assert.equal(await filtersPopup.locator('.filter-inherited-note').isVisible(),inherited);
          assert.equal(await filtersToggle.getAttribute('title'),null,'State needs no tooltip');
          iconStates.push({mode,inherited,nested,propagating});
        }
        if(inherited) {
          await page.screenshot({path:path.join(output,'filter-indicator-'+mode+'.png'),fullPage:true});
          await page.locator('.toolbar').screenshot({path:path.join(output,'filter-toolbar-'+mode+'.png')});
        }
      }
    }
    await filtersPopup.getByRole('radio',{name:'Белый список',exact:true}).check();
    for(const width of [1000,390,320]) {
      await page.setViewportSize({width,height:900});
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
      assert.equal(await filtersPopup.evaluate(el=>{const r=el.getBoundingClientRect();return r.left>=0 && r.right<=document.documentElement.clientWidth && el.scrollWidth<=el.clientWidth;}),true);
      await page.screenshot({path:path.join(output,'filters-inherited-'+width+'.png'),fullPage:true});
    }
    await fs.writeFile(path.join(output,'filter-indicator-states.json'),JSON.stringify(iconStates,null,2));
    await page.setViewportSize({width:1000,height:900});
    await page.goto(pathToFileURL(path.join(__dirname,'prototype.html')).href);
    assert.deepEqual(errors, [], 'Browser errors');
    const report = { passed: true, measurements, errors, output };
    await fs.writeFile(path.join(output, 'report.json'), JSON.stringify(report, null, 2));
    console.log(JSON.stringify(report, null, 2));
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
