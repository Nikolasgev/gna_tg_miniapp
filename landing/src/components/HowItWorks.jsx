import React from 'react'
import { motion } from 'framer-motion'
import { UserPlus, Settings, Rocket, CheckCircle2 } from 'lucide-react'

const HowItWorks = ({ onOpenModal }) => {
  const steps = [
    {
      number: '01',
      icon: UserPlus,
      title: 'Настройка бизнеса',
      description: 'Мы создаем ваш бизнес в системе и настраиваем админ-панель. Вы получаете доступ для управления товарами и заказами.',
      color: 'from-blue-500 to-cyan-500',
    },
    {
      number: '02',
      icon: Settings,
      title: 'Заполнение каталога',
      description: 'Вы добавляете товары через админ-панель: названия, фото, цены, категории. Настраиваем оплату (YooKassa) и доставку (Яндекс Доставка).',
      color: 'from-slate-600 to-slate-800',
    },
    {
      number: '03',
      icon: Rocket,
      title: 'Запуск магазина',
      description: 'Подключаем Telegram бота с Mini App. Ваши клиенты делают заказы в Telegram, а вы управляете всем через админ-панель.',
      color: 'from-orange-500 to-red-500',
    },
  ]

  return (
    <section id="how-it-works" className="py-20 bg-gradient-to-br from-gray-50 to-slate-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Как это <span className="text-gradient">работает</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Запустите свой магазин в Telegram всего за 3 простых шага
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8 relative">
          {/* Connection Line */}
          <div className="hidden md:block absolute top-20 left-1/4 right-1/4 h-1 bg-gradient-to-r from-slate-200 via-slate-300 to-slate-200"></div>

          {steps.map((step, index) => (
            <motion.div
              key={step.number}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.2 }}
              className="relative flex"
            >
              <div className="bg-white rounded-2xl p-8 shadow-lg hover:shadow-xl transition-all text-center w-full flex flex-col">
                {/* Number Badge */}
                <div className="absolute -top-6 left-1/2 transform -translate-x-1/2">
                  <div className="bg-gradient-to-br from-slate-700 to-slate-900 text-white w-12 h-12 rounded-full flex items-center justify-center font-bold text-lg shadow-lg">
                    {step.number}
                  </div>
                </div>

                {/* Icon */}
                <div className="mt-4 mb-6 flex justify-center">
                  <div
                    className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${step.color} p-5 shadow-lg`}
                  >
                    <step.icon className="w-full h-full text-white" />
                  </div>
                </div>

                {/* Content */}
                <h3 className="text-2xl font-bold text-gray-900 mb-3">
                  {step.title}
                </h3>
                <p className="text-gray-600 leading-relaxed flex-grow">
                  {step.description}
                </p>
              </div>
            </motion.div>
          ))}
        </div>

        {/* CTA Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="mt-16 text-center"
        >
          <div className="bg-white rounded-2xl p-8 shadow-lg max-w-2xl mx-auto">
            <CheckCircle2 className="w-16 h-16 text-slate-600 mx-auto mb-4" />
            <h3 className="text-2xl font-bold text-gray-900 mb-2">
              Готовы начать?
            </h3>
            <p className="text-gray-600 mb-6">
              Присоединяйтесь к сотням магазинов, которые уже продают в Telegram
            </p>
            <button
              onClick={onOpenModal}
              className="inline-block bg-gradient-to-r from-slate-700 to-slate-900 text-white px-8 py-4 rounded-full font-semibold text-lg shadow-lg hover:shadow-xl transition-all hover:scale-105"
            >
              Начать бесплатно
            </button>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default HowItWorks

