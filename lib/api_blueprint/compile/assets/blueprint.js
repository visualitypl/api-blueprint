(function() { 'use strict';
  $(function() {
    var docTitle = $('title').text();
    var addLinkToHistory = false;

    /* init href position */

    var href = window.location.href.split('#')[1];
    if (href) {
      var target = $('#' + href);
      if (target.length == 0) {
        href = href.replace(/^\d+\-/g, '');
        target = $('#' + href);
      }

      if (target.length) {
        $('html, body').scrollTop( target.offset().top - 20 );

        $(window).load(function() {
          $('html, body').scrollTop( target.offset().top - 20 );

          var interval = null, i = 0;

          interval = setInterval(function() {
            $('html, body').scrollTop( target.offset().top - 20 );
            ++i;

            if (i > 100) {
              clearInterval(interval);
            }
          }, 10);
        });
      }
    }

    /* wrap contents */

    var wrapFromTo = function(container, from, to) {
      $(from).each(function() {
        var starter = $(this);
        var wrapper = $(container);
        var content = starter.nextUntil(to);

        starter.before(wrapper);
        wrapper.append(starter);
        wrapper.append(content);
      });
    };

    wrapFromTo('<div class="toc">', "h1:contains('Table Of Contents')", 'h1');
    wrapFromTo('<div class="resource">', "h1:contains('Resource: ')", 'h1, p.footer');
    wrapFromTo('<div class="action">', ".resource > h2:contains('Action: ')", 'h2');
    wrapFromTo('<div class="description">', ".action > h3:contains('Description:')", 'h3:contains("Examples")');
    wrapFromTo('<div class="examples">', ".action > h3:contains('Examples:')", 'h3');
    wrapFromTo('<div class="example">', ".examples > h4:contains('Example: ')", 'h4');

    /* highlighting active toc */

    var markTocActive = function() {
      var pos = $(window).scrollTop() + 30;

      var resources = $('h1');
      var pickResource = resources[0]; // null;
      resources.each(function() {
        if ($(this).offset().top > pos) {
          return false;
        }
        pickResource = this;
      });

      var tocLinks = $('.toc a');
      tocLinks.removeClass('active');

      var actions = $('h2');
      var pickAction = null;
      actions.each(function() {
        if ($(this).offset().top > pos) {
          return false;
        }
        pickAction = this;
      });

      if (pickAction) {
        var id = $(pickAction).attr('id');
        var tocActionLink = $('.toc a[href="#' + id + '"]');

        tocActionLink.addClass('active');
      }

      if (pickResource) {
        var id = $(pickResource).attr('id');
        var tocLink = $('.toc a[href="#' + id + '"]');

        var currentTocSection = tocLink.closest('li');
        var otherSections = currentTocSection.siblings();
        var activeChildren = currentTocSection.find('ul li a.active').length > 0;

        tocLink.addClass('active');
        tocLink.toggleClass('active-children',
          activeChildren);
        otherSections.find('a').removeClass('active');

        currentTocSection.children('ul').slideDown();
        otherSections.children('ul').slideUp();

        if (history && history.replaceState) {
          if (activeChildren) {
            var newHash = tocActionLink.attr('href').split('#')[1];
            var newTitle = tocActionLink.text() + ' - ' + tocLink.text() + ' - ' + docTitle;
          } else {
            var newHash = tocLink.attr('href').split('#')[1];
            var newTitle = tocLink.text()  + ' - ' + docTitle;
          }

          if (window.location.hash.split('#')[1] != newHash || document.title != newTitle) {
            document.title = newTitle;

            var newUrl = window.location.href.split('#')[0] + '#' + newHash;
            var newData = { hash: newHash };

            if (addLinkToHistory) {
              history.pushState(newData, newTitle, newUrl);

              addLinkToHistory = false;
            } else {
              history.replaceState(newData, newTitle, newUrl);
            }
          }
        }
      }
    };

    $(window).scroll(markTocActive);
    markTocActive();

    /* scroll for toc links */

    var scrollToTarget = function(target) {
      if (target.length < 1) {
        return;
      }

      var position = target.offset().top;

      $('html, body').scrollTop( position + 80 ).animate({
        scrollTop: position - 20
      });
    };

    var scrollToLinkTarget = function(link) {
      addLinkToHistory = true;

      var selector = link.attr('href');
      var target = $(selector);

      scrollToTarget(target);

      return false;
    };

    window.onpopstate = function(event) {
      var hash = event.state.hash;
      if (!hash) {
        return;
      }

      var target = $('#' + hash);
      setTimeout(function() {
        scrollToTarget(target);
      }, 0);
    };

    /* prettify code */

    $('pre').addClass('prettyprint');
    $('h5:contains("headers:") + pre').removeClass('prettyprint');

    /* generate the curl requests */

    var getHost = function() {
      var host = $('#host');

      if (host.length && host.text().substr(0, 4) === 'http') {
        return host.text();
      } else if (window.location.host.length) {
        return window.location.protocol + '//' + window.location.host;
      } else {
        return 'http://www.example.com';
      }
    };

    var generateCurlExample = function(exampleContent) {
      if (exampleContent.find('.curl').length) {
        return;
      }

      var actionContent = exampleContent.closest('.action');
      var method = actionContent.find('h4:contains("Signature:") + p > strong').text().toUpperCase();
      if (method !== 'GET' && method !== 'POST' && method !== 'PATCH' && method !== 'DELETE') {
        return;
      }

      var path = actionContent.find('h4:contains("Signature:") + p > code').text();
      if (path[0] !== '/') {
        return;
      }

      var headers   = exampleContent.find('h5:contains("Request headers:") + pre').text();
      var params    = exampleContent.find('h5:contains("Request params:") + pre').text();
      var rawInfo   = exampleContent.children('h5:contains("Request"), h5:contains("Request") + pre');
      var prefix    = '     ', suffix = ' \\\\\n', curl = '';
      var multipart = !! headers.match(/multipart/);

      var rawWrapper = $('<div class="raw"></div>');
      exampleContent.children('h4').after(rawWrapper);
      rawWrapper.append(rawInfo);

      curl += 'curl --include' + suffix;
      curl += prefix + '--request ' + method + suffix;

      if (headers) {
        headers.split("\n").forEach(function(header) {
          if (header.length) {
            curl += prefix + '--header "' + header.replace(/\s+/, ' ') + '"' + suffix;
          }
        });
      }

      if (params && method !== 'GET') {
        if (multipart) {
          $.each($.param($.parseJSON(params)).split("&"), function(index, param) {
            var file = decodeURIComponent(param).match(/\S+\+\<(\S+?)\>/);

            if (file) {
              curl += prefix + '--form "' + decodeURIComponent(param).split('=')[0] + '=@' + file[1] + '"' + suffix;
            } else {
              curl += prefix + '--form "' + decodeURIComponent(param) + '"' + suffix;
            }
          });
        } else {
          curl += prefix + "--data-binary '" + params.replace(/\n+$/, '') + "'" + suffix;
        }
      }

      curl += prefix + '"' + getHost() + path;
      if (params && method === 'GET') {
        curl += '?' + $.param($.parseJSON(params)).replace(/&/g, '&amp;');
      }
      curl += '"';

      exampleContent.children('h4').after('<div class="curl"><h5>Request in cURL:</h5><pre><code>' + curl + '</code></pre></div>');

      var controls = $("<span class='format-toggle'><a class='as-raw' href=''>Raw</a><a class='as-curl' href=''>cURL</a></span>");
      exampleContent.find('> div h5:first-child').append(controls);
    }

    $(document).on('click', '.format-toggle a', function() {
      $('html').toggleClass('example-curl', $(this).hasClass('as-curl'));

      return false;
    });

    /* example unfolding */

    $(document).on('click', '.example > h4', function() {
      var thisExample = $(this).closest('.example');

      $('.example').not(thisExample).removeClass('visible');
      thisExample.toggleClass('visible');

      if (thisExample.hasClass('visible')) {
        generateCurlExample(thisExample);

        $('html, body').animate({
          scrollTop: thisExample.offset().top - 20
        });
      }

      return false;
    });

    $('h5:contains("Response headers:") + pre').filter(function(item) {
      var status = $(this).text().match(/Status\:\s*(\d+)/)[1];

      return (status && parseInt(status) > 0 && parseInt(status) >= 400);
    }).closest('.example').addClass('failed');

    /* cut unnecessary texts */

    $('.example > h4').each(function(header) {
      $(this).text($(this).text().replace('Example: ', ''))
    });

    /* add example status descriptions */

    $('.examples').append("<p class='example-description'>Examples that depict proper requests resulting in status 200 are marked with <em class='green'>green dots</em>, while those that depict wrong usage are marked with <em class='red'>red dots</em>.</p>")

    /* add & handle the toc hider */

    var tocHider = $('<a href="#" class="toc-hider"></a>');
    var tocHeader = $('.toc h1');
    tocHeader.after(tocHider);
    tocHider.append(tocHeader);

    tocHider.click(function() {
      $('html').toggleClass('hide-toc');

      return false;
    });

    /* mark js */

    $('html').addClass('js');

    /* handle param table */

    $('h4:contains("Parameters:") + table').addClass('parameters');

    $('table.parameters td:contains("[]")').each(function() {
      var td = $(this),
          level = td.text().match(/\[\]/g).length + 1,
          row = td.closest('tr');

      td.text(td.text().replace(/\[\]/g, ''));
      row.addClass('param-level-' + level);
    });

    $('table.parameters code:contains("Example:")').addClass('example').each(function() {
      $(this).text($(this).text().replace("Example:", ''));
    });

    $('table.parameters td:nth-child(2) strong:contains("required")').addClass("required");

    /* Autolink */

    $('a[href="#menu"]').addClass('menu-autolink');

    $(document).on('click', 'a[href="#menu"]', function() {
      var link = $(this);
      var text = link.text();
      var targetLink = $('.toc a:contains("' + text + '")');

      if (targetLink.length) {
        if (targetLink.length > 1) {
          targetLink.each(function() {
            var eachLink = $(this);

            if (eachLink.text() == text) {
              targetLink = eachLink;
              return false;
            }
          });
        }

        link.attr('href', targetLink.attr('href'));

        return scrollToLinkTarget(targetLink);
      }

      return false;
    });

    $('a[href="#example"]').addClass('example-autolink');

    $(document).on('click', 'a[href="#example"]', function(e) {
      var link = $(this);
      var text = link.text();
      var target = $('.example h4:contains("' + text + '")');

      if (target.length) {
        scrollToTarget(target);

        if (! target.closest('.example').hasClass('visible')) {
          target.click();
        }
      }

      return false;
    });

    $(document).on('click', 'a[href^="#"]', function() {
      return scrollToLinkTarget($(this));
    });
  });
})();


