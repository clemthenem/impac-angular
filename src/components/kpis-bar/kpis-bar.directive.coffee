angular
  .module('impac.components.kpis-bar', [])
  .directive('kpisBar', ($templateCache, ImpacKpisSvc, ImpacEvents, IMPAC_EVENTS) ->
    return {
      restrict: 'E'
      scope: {
        kpis: '='
      }
      template: $templateCache.get('kpis-bar/kpis-bar.tmpl.html')

      controller: ($scope, $timeout, $log) ->
        # Load
        # -------------------------
        $scope.availableKpis = {
          hide: true,
          toggle: ->
            $scope.availableKpis.hide = !$scope.availableKpis.hide
        }
        $scope.showKpisExpanded = false
        # All kpis edit panels are shown
        $scope.showEditMode = false
        $scope.isAddingKpi = false

        # references to services (bound objects shared between all controllers)
        # -------------------------------------
        ImpacKpisSvc.load().then ->
          initAvailableKpis()
          # QUICK FIX - see kpi.svc method for comments.
          _.forEach($scope.kpis, (kpi)-> ImpacKpisSvc.buildKpiWatchables(kpi))

        # $scope.keyStats = [
        #   { name: 'Interest', data: { value: '-15.30', unit: '%' }, static: true },
        #   { name: 'Profitability', data: { value: '8.34', unit: '%' }, static: true},
        #   { name: 'Cost of capital', data: { value: '20.00', unit: 'AUD' }, static: true},
        #   { name: 'TAX % based on FY14', data: { value: '29.91', unit: '%' }, static: true},
        #   { name: 'Super', data: { value: '479023', unit: 'AUD' }, static: true}
        # ]

        $scope.sortableOptions = {
          stop: ->
            ids = _.pluck $scope.kpis, 'id'
            ImpacKpisSvc.updateKpisOrder(ids)
          cursorAt:
            left: 100
            top: 20
          opacity: 0.5
          delay: 150
          tolerance: 'pointer'
          cursor: "move"
          revert: 250
          # only the top-line with title will provide the handle to drag/drop kpis
          handle: ".top-line"
          cancel: ".unsortable"
          helper: 'clone'
        }

        # Hist methods
        # -------------------------
        $scope.hist = {
          date:
            from: new Date(new Date().getFullYear(), 0, 1)
            to: new Date()
          opened:
            from: false
            to: false
          format: "yyyy-MM-dd"
        }

        $scope.openDateFrom = () ->
          $scope.hist.opened.from = true

        $scope.openDateTo = () ->
          $scope.hist.opened.to = true

        $scope.massDateAssignment = () ->
          console.log "Date changed"

        # Linked methods
        # -------------------------
        $scope.addKpi = (kpi) ->
          return if $scope.isAddingKpi
          $scope.isAddingKpi = true

          kpi.element_watched = kpi.watchables[0]

          # Removes element watched from the available watchables array and saves the rest as
          # extra watchabes.
          # TODO: mno & impac should be change to deal with `watchables`, instead
          # of element_watched, and extra_watchables. The first element of watchables should be
          # considered the primary watchable, a.k.a element_watched.
          opts = {}
          opts.extra_watchables = _.filter(kpi.watchables, (w)-> w != kpi.element_watched)

          ImpacKpisSvc.create(kpi.source || 'impac', kpi.endpoint, kpi.element_watched, opts).then(
            (success) ->
              $scope.kpis.push(success)
            (error) ->
              $log.error("Impac Kpis bar can't add a kpi", error)
          ).finally(->
            initAvailableKpis()
            $scope.isAddingKpi = false
          )

        $scope.removeKpi = (kpiId) ->
          _.remove $scope.kpis, (kpi) -> kpi.id == kpiId
          initAvailableKpis()

        $scope.toggleEditMode = ->
          if (kpiIsEditing() && !$scope.showEditMode)
            ImpacEvents.notifyCallbacks(IMPAC_EVENTS.kpisBarUpdateSettings)
          else
            ImpacEvents.notifyCallbacks(IMPAC_EVENTS.kpisBarUpdateSettings, f) if (f = $scope.showEditMode)
            $scope.showEditMode = !$scope.showEditMode
          $scope.availableKpis.toggle() unless $scope.availableKpis.hide || $scope.showEditMode

        $scope.isEditing = ->
          $scope.showEditMode || kpiIsEditing()

        # Private methods
        # -------------------------
        kpiIsEditing = ->
          _.includes(_.map($scope.kpis, (kpi)-> kpi.isEditing), true)

        initAvailableKpis = ->
          $scope.availableKpis.list = _.select(ImpacKpisSvc.getKpisTemplates(), (k) ->
            _.isEmpty(k.attachables) &&
            _.isEmpty(_.select($scope.kpis, (existingKpi) ->
              existingKpi.endpoint == k.endpoint && existingKpi.element_watched == k.watchables[0]
            ))
          )
          $scope.availableKpis.hide = true if _.isEmpty($scope.availableKpis.list)

    }
  )
